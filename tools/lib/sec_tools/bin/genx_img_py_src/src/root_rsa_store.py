from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_K0_BOOT = 0x1
K0_BOOT            = "K0_BOOT"

IMAGE_TYPE_K0_TEE  = 0x2
K0_TEE             = "K0_TEE"
IMAGE_TYPE_K0_REE  = 0x3
K0_REE             = "K0_REE"

SIZE_OF_ROOT_RSA_HEADER = 60
SIZE_OF_ROOT_RSA_BODY = 256
SIZE_OF_ROOT_RSA_STORE = SIZE_OF_ROOT_RSA_HEADER + SIZE_OF_ROOT_RSA_BODY
SIZE_OF_IMAGE_TYPE_K0_BOOT = SIZE_OF_ROOT_RSA_STORE
SIZE_OF_IMAGE_TYPE_K0_TEE = SIZE_OF_ROOT_RSA_STORE
SIZE_OF_IMAGE_TYPE_K0_REE = SIZE_OF_ROOT_RSA_STORE

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_root_rsa_store
        function
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len != CRYPTO_PUB_MODULUS_LEN:
        raise ErrInvalidParam('Invalid body length')

def generate_root_rsa_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the
        rsa image format and stores it inside a file
    '''
    check_params(params)

    iv = b'\x00' * CRYPTO_IV_LEN
    if not params.no_encryption:
        if params.iv_input_file != '':
            iv = params.iv
        else:
            iv = crypto_get_random(CRYPTO_IV_LEN)

    checksum = crypto_sha256(params.p_body)
    header = [
        int.to_bytes(params.image_type, 4, 'little'),
        int.to_bytes(params.image_format_version, 4, 'little'),
        int.to_bytes(SIZE_OF_ROOT_RSA_STORE, 4, 'little'),
        iv,
        checksum,
    ]
    header = b''.join(header)
    header_checksum = crypto_sha256(header)

    if not params.no_encryption:
        body = crypto_aes256_enc(params.p_body, params.aes_enc_key, iv)
    else:
        print('WARNING: Skipping encrypting modulus')
        body = params.p_body

    with open(params.store_output_file, 'wb') as output:
        output.write(header)
        output.write(body)

    with open(params.hash_output_file, 'wb') as output:
        output.write(header_checksum)
