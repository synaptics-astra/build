import struct

from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_DIF = 0x40
DIF            = "DIF"

SIZE_OF_DIF_IMAGE_STORE_HEADER = 60
SIZE_OF_DIF_IMAGE_STORE_SIGN   = 256
SIZE_OF_IMAGE_TYPE_DIF_EXTRA   = 4

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_dif_image_store
        function
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len == 0:
        raise ErrInvalidParam('Invalid body length - length 0')
    if params.body_len % CRYPTO_AES_KEY_LEN:
        raise ErrInvalidParam(f'Invalid body length - length not multiple of {CRYPTO_AES_KEY_LEN}')

def generate_dif_image_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the dif
        image format and stores it inside a file
    '''
    check_params(params)

    if not params.no_encryption:
        params.iv = crypto_get_random(CRYPTO_IV_LEN)

    if params.extras_len != SIZE_OF_IMAGE_TYPE_DIF_EXTRA:
        raise ErrParamExtraLen(f'Invalid extra length - length should be {SIZE_OF_IMAGE_TYPE_DIF_EXTRA}')

    header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', SIZE_OF_DIF_IMAGE_STORE_HEADER + params.extras_len + SIZE_OF_DIF_IMAGE_STORE_SIGN + params.body_len),
        params.iv.rjust(CRYPTO_IV_LEN, b'\x00'),
        crypto_sha256(params.p_body)
    ]
    header = b''.join(header)

    p_header = header + params.p_extras
    header_signature = crypto_rsa_sign(p_header, params.rsa_key_input_file)

    if not params.no_encryption:
        params.p_body = crypto_aes256_enc(params.p_body, params.aes_enc_key, params.iv)
    else:
        print('WARNING: Skipping encryption')

    with open(params.store_output_file, 'wb') as output:
        output.write(p_header)
        output.write(header_signature)
        output.write(params.p_body)

