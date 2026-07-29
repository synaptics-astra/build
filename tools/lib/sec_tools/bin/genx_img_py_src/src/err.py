class GenXError(Exception):
    exit_code = -1


class ErrParamOutfile(GenXError):
    exit_code = -27


class ErrParamAESKey(GenXError):
    exit_code = -21


class ErrParamNonce(GenXError):
    exit_code = -20


class ErrParamIV(GenXError):
    exit_code = -24


class ErrInvalidParam(GenXError):
    exit_code = -20


class ErrFileOpen(GenXError):
    exit_code = -10


class ErrCryptoRsaKey(GenXError):
    exit_code = -7


class ErrCryptoRsaSign(GenXError):
    exit_code = -5


class ErrCryptoSha256(GenXError):
    exit_code = -6


class ErrParamModulus(GenXError):
    exit_code = -26


class ErrCryptoRand(GenXError):
    exit_code = -8


class ErrCryptoAESEnc(GenXError):
    exit_code = -3


class ErrUnsupportedFormat(GenXError):
    exit_code = -40


class ErrParamRsa(GenXError):
    exit_code = -28


class ErrParamArg(GenXError):
    exit_code = -22


class ErrParamBody(GenXError):
    exit_code = -23


class ErrParamExtraArg(GenXError):
    exit_code = -29


class ErrParamExtraLen(GenXError):
    exit_code = -30

