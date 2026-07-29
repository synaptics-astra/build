import struct

from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_K1_BOOT_A = 0x4
K1_BOOT_A            = "K1_BOOT_A"
IMAGE_TYPE_K1_BOOT_B = 0x5
K1_BOOT_B            = "K1_BOOT_B"
IMAGE_TYPE_K1_TEE_A  = 0x6
K1_TEE_A             = "K1_TEE_A"
IMAGE_TYPE_K1_TEE_B  = 0x7
K1_TEE_B             = "K1_TEE_B"
IMAGE_TYPE_K1_TEE_C  = 0x8
K1_TEE_C             = "K1_TEE_C"
IMAGE_TYPE_K1_TEE_D  = 0x9
K1_TEE_D             = "K1_TEE_D"
IMAGE_TYPE_K1_REE_A  = 0xA
K1_REE_A             = "K1_REE_A"
IMAGE_TYPE_K1_REE_B  = 0xB
K1_REE_B             = "K1_REE_B"
IMAGE_TYPE_K1_REE_C  = 0xC
K1_REE_C             = "K1_REE_C"
IMAGE_TYPE_K1_REE_D  = 0xD
K1_REE_D             = "K1_REE_D"

SIZE_OF_LEVEL1_RSA_STORE_HEADER = 32
SIZE_OF_LEVEL1_RSA_STORE_BODY   = CRYPTO_PUB_MODULUS_LEN
SIZE_OF_LEVEL1_RSA_STORE_SIGN   = CRYPTO_RSA_SIGN_LEN

SIZE_OF_LEVEL1_RSA_STORE = SIZE_OF_LEVEL1_RSA_STORE_HEADER \
					 + SIZE_OF_LEVEL1_RSA_STORE_BODY \
					 + SIZE_OF_LEVEL1_RSA_STORE_SIGN 

SIZE_OF_IMAGE_TYPE_K1_BOOT_A = SIZE_OF_LEVEL1_RSA_STORE 
SIZE_OF_IMAGE_TYPE_K1_BOOT_B = SIZE_OF_LEVEL1_RSA_STORE 
SIZE_OF_IMAGE_TYPE_K1_TEE_A  = SIZE_OF_LEVEL1_RSA_STORE 
SIZE_OF_IMAGE_TYPE_K1_TEE_B  = SIZE_OF_LEVEL1_RSA_STORE
SIZE_OF_IMAGE_TYPE_K1_TEE_C  = SIZE_OF_LEVEL1_RSA_STORE
SIZE_OF_IMAGE_TYPE_K1_REE_A  = SIZE_OF_LEVEL1_RSA_STORE

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_root_rsa_store
        function
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len != SIZE_OF_LEVEL1_RSA_STORE_BODY:
        raise ErrInvalidParam('Invalid body length')

def generate_level1_rsa_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the level1
        rsa image format and stores it inside a file
    '''
    check_params(params)

    # like the exact order in the original c struct
    header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', SIZE_OF_LEVEL1_RSA_STORE),
        struct.pack('I', params.seg_id),
        struct.pack('I', params.seg_id_mask),
        struct.pack('I', params.version),
        struct.pack('I', params.version_mask),
        struct.pack('I', params.production_key_flag),
        params.p_body
    ]
    header = b''.join(header)

    signature = crypto_rsa_sign(header, params.rsa_key_input_file)
    header += signature
    with open(params.store_output_file, 'wb') as output:
        output.write(header)
