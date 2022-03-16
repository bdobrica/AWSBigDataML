from typing import Union
import sys
import getpass
from ykman.device import connect_to_device
from yubikit.core.smartcard import ApduError, SW, SmartCardConnection
from ykman.settings import AppData
from yubikit.oath import OathSession, OATH_TYPE
from ykman.oath import is_steam, is_hidden, calculate_steam
from threading import Timer

class YubiKey:
    def __init__(self):
        connection, device, info = connect_to_device(
            connection_types=[SmartCardConnection],
        )

        self.creds = None
        self.connection = connection
        self.device = device
        self.info = info

    def validate(self, key, remember):
        try:
            self.session.validate(key)
            if remember:
                keys = self.settings.setdefault('keys', {})
                keys[self.session.device_id] = key.hex()
                self.settings.write()
                sys.stderr.write('Password remembered.')
        except Exception:
            sys.stderr.write(
                'Authentication to the YubiKey failed. Wrong password?')
            exit(0)

    def get_session(self, password: str = None, remember: bool = True):
        self.session = OathSession(self.connection)
        self.settings = AppData('oath')
        keys = self.settings.setdefault('keys', {})
        device_id = self.session.device_id

        if self.session.locked:
            if password:  # If password argument given, use it
                key = self.session.derive_key(password)
            elif device_id in keys:  # If remembered, use key
                key = bytes.fromhex(keys[device_id])
            else:  # Prompt for password
                password = getpass.getpass('Enter the password:')
                key = self.session.derive_key(password)
            self.validate(key, remember)
        elif password:
            sys.stderr.write('Password provided, but no password is set.')

    def string_id(self, credential) -> str:
        return credential.id.decode('utf-8')

    def search(self, keys):
        self.creds = []
        for c in keys:
            cred_id = self.string_id(c)
            if not self.show_hidden and is_hidden(c):
                continue
            if cred_id == self.query:
                self.creds = [c]
                break
            if self.query.lower() in cred_id.lower():
                self.creds.append(c)

    def prompt_for_touch(self):
        sys.stderr.write('Touch your YubiKey...\n')

    def prompt_timeout(self, timeout: float = 0.5):
        timer = Timer(timeout, prompt_for_touch)
        try:
            timer.start()
            yield None
        finally:
            timer.cancel()

    def error_multiple_hits(self):
        sys.stderr.write(
            'Error: Multiple matches, please make the query more specific.\n')
        sys.stderr.write('\n')
        for cred in hits:
            sys.stderr.write(self.string_id(cred) + '\n')
        exit(0)

    def get_credentials(self):
        entries = self.session.calculate_all()
        self.search(entries.keys())

        if len(self.creds) == 1:
            cred = self.creds[0]
            code = entries[cred]
            if cred.touch_required:
                self.prompt_for_touch()
            try:
                if cred.oath_type == OATH_TYPE.HOTP:
                    with self.prompt_timeout():
                        # HOTP might require touch, we don't know.
                        # Assume yes after 500ms.
                        code = self.session.calculate_code(cred)
                elif code is None:
                    code = self.session.calculate_code(cred)
            except ApduError as e:
                if e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED:
                    sys.stderr.write('Touch account timed out!')
                    exit(0)
            entries[cred] = code

        elif self.single and len(self.creds) > 1:
            self.error_multiple_hits()
        
        elif self.single and len(self.creds) == 0:
            sys.stderr.write('No matching account found.')
            exit(0)
        
        if self.single and self.creds:
            cred = self.creds[0]
            if is_steam(cred):
                return calculate_steam(self.session, cred)
            else:
                return code.value
        else:
            outputs = []
            for cred in sorted(self.creds):
                code = entries[cred]
                if code:
                    if is_steam(cred):
                        code = calculate_steam(session, cred)
                    else:
                        code = code.value
                elif cred.touch_required:
                    code = '[Requires Touch]'
                elif cred.oath_type == OATH_TYPE.HOTP:
                    code = '[HOTP Account]'
                else:
                    code = ''
                outputs.append((self.string_id(cred), code))

            return dict(outputs)
    
    def get_hotp(self,
        password: str = None,
        remember: bool = False,
        query: str = '',
        single: bool = False,
        show_hidden: bool = False
    ) -> Union[dict, str]:
        self.query = query
        self.single = single
        self.show_hidden = show_hidden
        self.get_session(password, remember)
        return self.get_credentials()