import struct

from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_MODEL = 0x71
MODEL            = "MODEL"

SIZE_OF_MODEL_IMAGE_STORE_HEADER_TYPE = 108
SIZE_OF_MODEL_IMAGE_STORE_SIGN        = 256
SIZE_OF_IMAGE_TYPE_MODEL_EXTRA        = 16

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_model_image_store
        function
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len == 0:
        raise ErrInvalidParam('Invalid body length - length 0')
    if params.body_len % CRYPTO_AES_KEY_LEN:
        raise ErrInvalidParam(f'Invalid body length - length not multiple of {CRYPTO_AES_KEY_LEN}')
    if params.p_body_extra == b'':
        raise ErrInvalidParam('params.p_body_extra is empty')
    if params.body_len_extra == 0:
        raise ErrInvalidParam('Invalid extra body length - length 0')
    if params.body_len_extra % CRYPTO_AES_KEY_LEN:
        raise ErrInvalidParam(f'Invalid extra body length - length not multiple of {CRYPTO_AES_KEY_LEN}')
    
def generate_model_image_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the 
        model image format and stores it inside a file
    '''
    check_params(params)
    if params.iv_input_file == '':
        params.iv = crypto_get_random(CRYPTO_IV_LEN)
    
    if params.extras_len != SIZE_OF_IMAGE_TYPE_MODEL_EXTRA:
        raise ErrParamExtraLen(f'Invalid extra len - should be {SIZE_OF_IMAGE_TYPE_MODEL_EXTRA}')

    p_type_1_header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', SIZE_OF_MODEL_IMAGE_STORE_HEADER_TYPE + params.extras_len + SIZE_OF_MODEL_IMAGE_STORE_SIGN + params.body_len_extra + params.body_len),
        params.iv.rjust(CRYPTO_IV_LEN, b'\x00'),
        crypto_sha256(params.p_body_extra),
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
        header_signature = b'\x00'*SIZE_OF_MODEL_IMAGE_STORE_SIGN

    if not params.no_encryption:
        params.p_body = crypto_aes256_enc(params.p_body, params.aes_enc_key, params.iv)
    else:
        print('WARNING: Skipping encryption')
    
    with open(params.store_output_file, 'wb') as output:
        output.write(p_type_1_header)
        output.write(header_signature)
        output.write(params.p_body_extra)
        output.write(params.p_body)
