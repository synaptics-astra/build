import sys
from src.params_parser import *


def main(params: StoreParamsT) -> int:
    if any((IMAGE_TYPE_K0_BOOT == params.image_type,
           IMAGE_TYPE_K0_TEE == params.image_type,
           IMAGE_TYPE_K0_REE == params.image_type,
           IMAGE_TYPE_EROM == params.image_type,
           IMAGE_TYPE_BCM_KERNEL == params.image_type,
           IMAGE_TYPE_K1_BOOT_A == params.image_type,
           IMAGE_TYPE_K1_BOOT_B == params.image_type,
           IMAGE_TYPE_K1_TEE_A == params.image_type,
           IMAGE_TYPE_K1_TEE_B == params.image_type,
           IMAGE_TYPE_K1_TEE_C == params.image_type,
           IMAGE_TYPE_K1_TEE_D == params.image_type,
           IMAGE_TYPE_K1_REE_A == params.image_type,
           IMAGE_TYPE_K1_REE_B == params.image_type,
           IMAGE_TYPE_K1_REE_C == params.image_type,
           IMAGE_TYPE_K1_REE_D == params.image_type)):
        params.image_format_version = 0
    else:
        params.image_format_version = 1

    try:
        match params.image_format:
            case ImageFormatT.FORMAT_ROOT_RSA:
                if fetch_root_rsa_params(params):
                    generate_root_rsa_store(params)

            case ImageFormatT.FORMAT_EXT_RSA:
                if fetch_ext_rsa_params(params):
                    generate_level1_rsa_store(params)

            case ImageFormatT.FORMAT_BOOT_IMAGE:
                if fetch_boot_image_params(params):
                    generate_boot_image_store(params)

            case ImageFormatT.FORMAT_BOOT_IMAGE_TYPE2:
                if fetch_boot_image_params(params):
                    generate_boot_image_store_type2(params)

            case ImageFormatT.FORMAT_DIF_IMAGE:
                if fetch_boot_image_params(params):
                    generate_dif_image_store(params)

            case ImageFormatT.FORMAT_DDR_FW_IMAGE:
                if fetch_boot_image_params(params):
                    generate_ddr_fw_image_store(params)

            case ImageFormatT.FORMAT_MODEL_IMAGE:
                if fetch_boot_image_params(params):
                    generate_model_image_store(params)

            case ImageFormatT.FORMAT_OEM_COMMAND_IMAGE:
                if fetch_boot_image_params(params):
                    generate_oem_command_store(params)
                
            case _:
                raise ErrUnsupportedFormat('Invalid image format provided')
        
        return 0
    
    except GenXError as e:
        print(f'{type(e).__name__}: {str(e)}', file=sys.stderr)
        return e.exit_code

    except Exception as e:
        print(f'{type(e).__name__}: {str(e)}', file=sys.stderr)
        return -1

if __name__ == '__main__':
    parser = create_parser()
    try:
        args = parser.parse_args()
    except SystemExit as exc:
        if exc.code == 0:
            raise
        sys.exit(ErrParamArg.exit_code)

    # no arguments were passed
    if not any(vars(args).values()):
        parser.print_help()
        print('\nroot-rsa-types : { K0_BOOT | K0_TEE | K0_REE }\n'
              'level1-rsa-types : { K1_BOOT_[A|B] | K1_TEE_[A|B|C|D] | K1_REE_[A|B|C|D] }\n'
              'boot-img-types : { EROM | BOOTMONITOR | SYS_INIT | MINILOADER | BCM_KERNEL | ... }')
        sys.exit(ErrParamArg.exit_code)
    else:
        params = load_params(args)
        sys.exit(main(params))

