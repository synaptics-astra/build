import struct

from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_EROM                 = 0x10
EROM                            = "EROM"
IMAGE_TYPE_SCS_DATA_PARAM       = 0x11
SCS_DATA_PARAM                  = "SCS_DATA_PARAM"
IMAGE_TYPE_BOOTMONITOR          = 0x12
BOOTMONITOR                     = "BOOTMONITOR"
IMAGE_TYPE_SYS_INIT             = 0x13
SYS_INIT                        = "SYS_INIT"
IMAGE_TYPE_MINILOADER           = 0x14
MINILOADER                      = "MINILOADER"
IMAGE_TYPE_BCM_KERNEL           = 0x15
BCM_KERNEL                      = "BCM_KERNEL"
IMAGE_TYPE_TZ_KERNEL            = 0x16
TZ_KERNEL                       = "TZ_KERNEL"
IMAGE_TYPE_ATF                  = 0x17
ATF                             = "ATF"
IMAGE_TYPE_TZK_BOOT_PARAMETER   = 0x18
TZK_BOOT_PARAMETER              = "TZK_BOOT_PARAMETER"
IMAGE_TYPE_TA_ROOT_CERT         = 0x19
TA_ROOT_CERT                    = "TA_ROOT_CERT"
IMAGE_TYPE_TA_CERT              = 0x1A
TA_CERT                         = "TA_CERT"
IMAGE_TYPE_TA                   = 0x1B
TA                              = "TA"
IMAGE_TYPE_TZK_CONTAINER_HEADER = 0x1C
TZK_CONTAINER_HEADER            = "TZK_CONTAINER_HEADER"

# ACPU REE images
IMAGE_TYPE_BOOT_LOADER      = 0x20
BOOT_LOADER                 = "BOOT_LOADER"
IMAGE_TYPE_LINUX_KERNEL     = 0x21
LINUX_KERNEL                = "LINUX_KERNEL"
IMAGE_TYPE_TZK_OEM_SETTINGS = 0x22
TZK_OEM_SETTINGS            = "TZK_OEM_SETTINGS"
IMAGE_TYPE_AVB_KEYS         = 0x23
AVB_KEYS                    = "AVB_KEYS"
IMAGE_TYPE_UBOOT            = 0x25
UBOOT                       = "UBOOT"
IMAGE_TYPE_FASTBOOT         = 0x26
FASTBOOT                    = "FASTBOOT"
IMAGE_TYPE_FASTLOGO         = 0x27
FASTLOGO                    = "FASTLOGO"

# Other CPU FW images
IMAGE_TYPE_TSP_FW      = 0x30
TSP_FW                 = "TSP_FW"
IMAGE_TYPE_DSP_FW      = 0x31
DSP_FW                 = "DSP_FW"
IMAGE_TYPE_GPU_FW      = 0x32
GPU_FW                 = "GPU_FW"
IMAGE_TYPE_SM_FW       = 0x34
SM_FW                  = "SM_FW"
IMAGE_TYPE_DOLBY_AUDIO = 0x70
DOLBY_AUDIO            = "DOLBY_AUDIO"

SIZE_OF_BOOT_IMAGE_STORE_HEADER_TYPE1   = 76
SIZE_OF_BOOT_IMAGE_STORE_HEADER_TYPE2   = 28
SIZE_OF_BOOT_IMAGE_STORE_SIGN           = 256

SIZE_OF_IMAGE_TYPE_EROM_EXTRA               = 196
SIZE_OF_IMAGE_TYPE_SCS_DATA_PARAM_EXTRA     = 4
SIZE_OF_IMAGE_TYPE_BOOTMONITOR_EXTRA        = 4
SIZE_OF_IMAGE_TYPE_SYS_INIT_EXTRA           = 36
SIZE_OF_IMAGE_TYPE_MINILOADER_EXTRA         = 4
SIZE_OF_IMAGE_TYPE_UBOOT_EXTRA              = 4
SIZE_OF_IMAGE_TYPE_BCM_KERNEL_EXTRA         = 196
SIZE_OF_IMAGE_TYPE_TZ_KERNEL_EXTRA          = 8
SIZE_OF_IMAGE_TYPE_ATF_EXTRA                = 8
SIZE_OF_IMAGE_TYPE_TZK_BOOT_PARAMETER_EXTRA = 8
SIZE_OF_IMAGE_TYPE_TA_ROOT_CERT_EXTRA       = 8
SIZE_OF_IMAGE_TYPE_TA_CERT_EXTRA            = 12
SIZE_OF_IMAGE_TYPE_TA_EXTRA                 = 48
SIZE_OF_IMAGE_TYPE_GPU_FW_EXTRA             = 16
SIZE_OF_IMAGE_TYPE_DSP_FW_EXTRA             = 16
SIZE_OF_IMAGE_TYPE_TSP_FW_EXTRA             = 16
SIZE_OF_IMAGE_TYPE_SM_FW_EXTRA              = 4
SIZE_OF_IMAGE_TYPE_BOOT_LOADER_EXTRA        = 4
SIZE_OF_IMAGE_TYPE_FASTBOOT_EXTRA           = 4
SIZE_OF_IMAGE_TYPE_FASTLOGO_EXTRA           = 4
SIZE_OF_IMAGE_TYPE_LINUX_KERNEL_EXTRA       = 4
SIZE_OF_IMAGE_TYPE_TZK_OEM_SETTINGS_EXTRA   = 8
SIZE_OF_IMAGE_TYPE_AVB_KEYS_EXTRA           = 4
SIZE_OF_IMAGE_TYPE_DOLBY_AUDIO_EXTRA        = 4

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_boot_image_store
        and generate_boot_image_store_type2 functions
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len == 0:
        raise ErrInvalidParam('Invalid body length')
    if params.body_len % CRYPTO_AES_KEY_LEN:
        raise ErrInvalidParam('Invalid body length')

def get_header_len(image_type: int, body_len: int, extra_len: int) -> int:
    '''
        This function return the header length based on the image type,
        body length and the extra length provided
    '''
    lengths = {
        IMAGE_TYPE_EROM               : SIZE_OF_IMAGE_TYPE_EROM_EXTRA,
        IMAGE_TYPE_BCM_KERNEL         : SIZE_OF_IMAGE_TYPE_BCM_KERNEL_EXTRA,
        IMAGE_TYPE_BOOTMONITOR        : SIZE_OF_IMAGE_TYPE_BOOTMONITOR_EXTRA,
        IMAGE_TYPE_LINUX_KERNEL       : SIZE_OF_IMAGE_TYPE_LINUX_KERNEL_EXTRA,
        IMAGE_TYPE_SYS_INIT           : SIZE_OF_IMAGE_TYPE_SYS_INIT_EXTRA,
        IMAGE_TYPE_DSP_FW             : SIZE_OF_IMAGE_TYPE_DSP_FW_EXTRA,
        IMAGE_TYPE_MINILOADER         : SIZE_OF_IMAGE_TYPE_MINILOADER_EXTRA,
        IMAGE_TYPE_UBOOT              : SIZE_OF_IMAGE_TYPE_UBOOT_EXTRA,
        IMAGE_TYPE_TZ_KERNEL          : SIZE_OF_IMAGE_TYPE_TZ_KERNEL_EXTRA,
        IMAGE_TYPE_ATF                : SIZE_OF_IMAGE_TYPE_ATF_EXTRA,
        IMAGE_TYPE_TZK_BOOT_PARAMETER : SIZE_OF_IMAGE_TYPE_TZK_BOOT_PARAMETER_EXTRA,
        IMAGE_TYPE_TZK_OEM_SETTINGS   : SIZE_OF_IMAGE_TYPE_TZK_OEM_SETTINGS_EXTRA,
        IMAGE_TYPE_AVB_KEYS           : SIZE_OF_IMAGE_TYPE_AVB_KEYS_EXTRA,
        IMAGE_TYPE_BOOT_LOADER        : SIZE_OF_IMAGE_TYPE_BOOT_LOADER_EXTRA,
        IMAGE_TYPE_FASTBOOT           : SIZE_OF_IMAGE_TYPE_FASTBOOT_EXTRA,
        IMAGE_TYPE_FASTLOGO           : SIZE_OF_IMAGE_TYPE_FASTLOGO_EXTRA,
        IMAGE_TYPE_TA_ROOT_CERT       : SIZE_OF_IMAGE_TYPE_TA_ROOT_CERT_EXTRA,
        IMAGE_TYPE_TA_CERT            : SIZE_OF_IMAGE_TYPE_TA_CERT_EXTRA,
        IMAGE_TYPE_TA                 : SIZE_OF_IMAGE_TYPE_TA_EXTRA,
        IMAGE_TYPE_GPU_FW             :  SIZE_OF_IMAGE_TYPE_GPU_FW_EXTRA,
        IMAGE_TYPE_TSP_FW             : SIZE_OF_IMAGE_TYPE_TSP_FW_EXTRA,
        IMAGE_TYPE_SM_FW              : SIZE_OF_IMAGE_TYPE_SM_FW_EXTRA,
        IMAGE_TYPE_DOLBY_AUDIO        : SIZE_OF_IMAGE_TYPE_DOLBY_AUDIO_EXTRA
    }

    length = lengths.get(image_type, None)
    if length:
        if extra_len != length:
            raise ErrParamExtraLen(f'Invalid extra length - should be {length}')
        else:
            return SIZE_OF_BOOT_IMAGE_STORE_HEADER_TYPE1 + extra_len + SIZE_OF_BOOT_IMAGE_STORE_SIGN + body_len
    else:
        raise ErrParamExtraLen('Could not find the provided image type')

def generate_boot_image_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the
        boot image format and stores it inside a file
    '''
    check_params(params)

    if params.iv_input_file == '':
        params.iv = crypto_get_random(CRYPTO_IV_LEN)
    
    p_type_1_header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', get_header_len(params.image_type, params.body_len, params.extras_len)),
        params.iv,
        crypto_sha256(params.p_body),
        struct.pack('I', params.seg_id),
        struct.pack('I', params.seg_id_mask),
        struct.pack('I', params.version),
        struct.pack('I', params.version_mask),
        params.p_extras
    ]
    p_type_1_header = b''.join(p_type_1_header)

    if not params.no_signature:
        header_signature = crypto_rsa_sign(p_type_1_header, params.rsa_key_input_file)
    else:
        header_signature = b'\x00'*SIZE_OF_BOOT_IMAGE_STORE_SIGN

    if not params.no_encryption:
        params.p_body = crypto_aes256_enc(params.p_body, params.aes_enc_key, params.iv)
    else:
        print('WARNING: Skipping encryption')
    
    with open(params.store_output_file, 'wb') as output:
        output.write(p_type_1_header)
        output.write(header_signature)
        output.write(params.p_body)

def generate_boot_image_store_type2(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the boot
        type2 image format and stores it inside a file
    '''
    check_params(params)
    
    if params.extras_len != SIZE_OF_IMAGE_TYPE_SCS_DATA_PARAM_EXTRA:
        raise ErrParamExtraLen(f'Invalid extras length - should be {SIZE_OF_IMAGE_TYPE_SCS_DATA_PARAM_EXTRA}')

    p_type_2_header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', SIZE_OF_BOOT_IMAGE_STORE_HEADER_TYPE2 + params.extras_len + params.body_len + SIZE_OF_BOOT_IMAGE_STORE_SIGN),
        struct.pack('I', params.seg_id),
        struct.pack('I', params.seg_id_mask),
        struct.pack('I', params.version),
        struct.pack('I', params.version_mask),
        params.p_extras,
        params.p_body
    ]
    p_type_2_header = b''.join(p_type_2_header)

    header_signature = crypto_rsa_sign(p_type_2_header, params.rsa_key_input_file)

    with open(params.store_output_file, 'wb') as output:
        output.write(p_type_2_header)
        output.write(header_signature)
