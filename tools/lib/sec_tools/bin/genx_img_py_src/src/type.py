import argparse
from enum import Enum

class CustomFormatter(argparse.HelpFormatter):
    def _format_action_invocation(self, action):
        if not action.option_strings:
            metavar, = self._metavar_formatter(action, action.dest)(1)
            return metavar

        if action.nargs == 0:
            return ', '.join(action.option_strings)

        default = self._get_default_metavar_for_optional(action)
        args_string = self._format_args(action, default)
        return f"{', '.join(action.option_strings)} {args_string}"

class ImageFormatT(Enum):
    FORMAT_UNKNOWN = 0
    FORMAT_ROOT_RSA = 1
    FORMAT_EXT_RSA = 2
    FORMAT_BOOT_IMAGE = 3
    FORMAT_BOOT_IMAGE_TYPE2 = 4
    FORMAT_DIF_IMAGE = 5
    FORMAT_DDR_FW_IMAGE = 6
    FORMAT_MODEL_IMAGE = 7
    FORMAT_OEM_COMMAND_IMAGE = 8

class StoreParamsT:
    def __init__(self) -> None:
        self.image_format: ImageFormatT = ImageFormatT.FORMAT_UNKNOWN
        self.image_type: int = 0
        self.aes_enc_key: bytes = b''
        self.iv: bytes = b'\x00' * 16
        self.image_format_version: int = 0
        self.production_key_flag: int = 0
        self.seg_id: int = 0
        self.seg_id_mask: int = 0
        self.version: int = 0
        self.version_mask: int = 0
        self.p_body: bytes = b''
        self.p_body_extra: bytes = b''
        self.body_len: int = 0
        self.body_len_extra: int = 0
        self.p_extras: bytes = b''
        self.extras_len: int = 0
        self.requested_length: int = 0
        
        self.arg_num: int = 0
        self.aes_key_input_file: str = ""
        self.iv_input_file: str = ""
        self.rsa_key_input_file: str = ""
        self.store_output_file: str = ""
        self.hash_output_file: str = ""
        self.payload_input_file: str = ""
        self.payload_input_file_extra: str = ""
        self.extra_input_file: str = ""
        self.no_encryption: bool = False
        self.no_signature: bool = False

