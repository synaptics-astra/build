from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15
from Crypto.Cipher import AES
from Crypto.Hash import SHA256

from Crypto.Random import get_random_bytes
from Crypto.Util.number import long_to_bytes

from .err import *
from .type import StoreParamsT

CRYPTO_AES_KEY_LEN     = 16
CRYPTO_IV_LEN          = 16
CRYPTO_NONCE_LEN       = 12
CRYPTO_CHECKSUM_LEN    = 32
CRYPTO_PUB_MODULUS_LEN = 256
CRYPTO_RSA_SIGN_LEN    = 256

def crypto_get_rsa_modulus(params: StoreParamsT) -> bool:
    '''
        This function retrieves n from the public key
        and stores it as bytes in the params object
    '''
    if params.payload_input_file == '':
        raise ErrInvalidParam('Did not provide payload input file')
    
    try:
        with open(params.payload_input_file, 'rb') as pub_key:
            cert = pub_key.read()
        key = RSA.import_key(cert)

        if key.n.bit_length() <= 0:
            raise ErrCryptoRsaKey('Invalid n value')

        p_body = long_to_bytes(key.n)
        body_len = len(p_body)
        if body_len == 0:
            raise ErrCryptoRsaKey('Invalid n value')
        
        params.p_body = p_body
        params.body_len = body_len
    except:
        raise ErrFileOpen('Cannot open the provided file')
    
    return True

def crypto_get_random(length: int) -> bytes:
    '''
        This function returns random bytes based on the length provided
    '''
    try:
        return get_random_bytes(length)
    except Exception as exc:
        raise ErrCryptoRand(str(exc)) from exc

def crypto_sha256(msg: bytes) -> bytes:
    '''
        This function return the sha256 of the bytes given
    '''
    try:
        hashed_data = SHA256.new(msg).digest()
    except Exception as exc:
        raise ErrCryptoSha256(str(exc)) from exc
    return hashed_data

def crypto_aes256_enc(plaintext: bytes, key: bytes, iv: bytes = b'\x00') -> bytes:
    '''
        This function encrypt the plaintext based on the key and the iv using
        aes mode cbc
    '''
    try:
        cipher = AES.new(key, AES.MODE_CBC, iv=iv)
        while len(plaintext) % 16 != 0:
            plaintext += b'\x00'

        return cipher.encrypt(plaintext)
    except Exception as exc:
        raise ErrCryptoAESEnc(str(exc)) from exc

def crypto_aes256_dec(ciphertext: bytes, key: bytes, iv: bytes) -> bytes:
    '''
        This function decrypt the ciphertext based on the key and the iv using
        aes mode cbc
    '''
    cipher = AES.new(key, AES.MODE_CBC, iv=iv)
    # removing the NULL padding, if exists
    return cipher.decrypt(ciphertext).rstrip(b'\x00')

def crypto_rsa_sign(msg: bytes, rsa_key_path: str) -> bytes:
    '''
        This functions signs a message using a private rsa
        key using the SHA256 digest
    '''
    try:
        with open(rsa_key_path, 'rb') as pub_key:
            cert = pub_key.read()
    except OSError as exc:
        raise ErrParamRsa(str(exc)) from exc

    try:
        key = RSA.import_key(cert)
        signature = pkcs1_15.new(key).sign(SHA256.new(msg))
    except Exception as exc:
        raise ErrCryptoRsaSign(str(exc)) from exc

    if len(signature) != CRYPTO_RSA_SIGN_LEN:
        raise ErrCryptoRsaSign(
            f'Invalid signature length ({len(signature)} bytes), expected {CRYPTO_RSA_SIGN_LEN}'
        )

    return signature

