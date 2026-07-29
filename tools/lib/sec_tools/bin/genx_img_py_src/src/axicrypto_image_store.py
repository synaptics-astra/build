import struct

from .crypto import *


def check_params(params: StoreParamsT) -> None:
	'''
		This function checks the parameters for generate_ddr_fw_image_store
		function
	'''
	if params.p_body == b'':
		raise ErrInvalidParam('params.p_body is empty')
	if params.body_len == 0:
		raise ErrInvalidParam('Invalid body length - length 0')
	if params.body_len % CRYPTO_AES_KEY_LEN:
		raise ErrInvalidParam(f'Invalid body length - length not multiple of {CRYPTO_AES_KEY_LEN}')


def generate_axicrypto_image_store(params: StoreParamsT) -> None:
	'''
		This function generates the encrypted image based on the
		axi crypto OTF format and stores it inside a file
	'''
	check_params(params)

	# AXI crypto encryption should encrypt all the given block -> include boot command etc.
	if not params.no_encryption:
		p_full_image = crypto_aes256_enc(plaintext=params.p_body, key=params.aes_enc_key, mode=AES.MODE_CTR,
										 nonce=params.nonce, start_address=params.start_address,
										 address_offset=params.address_offset)
	else:
		print('WARNING: Skipping encryption')
		p_full_image = params.p_body


	with open(params.store_output_file, 'wb') as output:
		output.write(p_full_image)
