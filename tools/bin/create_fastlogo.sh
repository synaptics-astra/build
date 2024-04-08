#/bin/sh


append_binary8(){

 printf "0: %.8x" $1 | sed -E 's/0: (..)(..)(..)(..)/0: \4\3\2\1/' | xxd -r -g0 >>$2
}
append_binary4(){

 printf "0: %.2x" $1  | xxd -r -g0 >>$2
}

append_header(){
width=$1
height=$2
let stride=$1*2

append_binary8 $width $3
append_binary8 $height $3
append_binary8 $stride $3

}

append_zero(){

dd if=/dev/zero bs=$1 count=1 >> $2

}

help() {
cat <<-_EOF_
        Usage:
        ${my_name} -i iFILE -o oFILE

       Options:
        -i  input image 1920x1080 BMP.

        -o output image. example: fastlogo.subimg

        -o FILE
_EOF_
}

main() {
        local OPT OPTARG
        local ofile ifile

        while getopts :ho:i: OPT; do
                case "${OPT}" in
                        h)  help; exit 0;;
                        o)  ofile="${OPTARG}";;
                        i)  ifile="${OPTARG}";;
                        :)  error "option '%s' expects a mandatory argument\n" "${OPTARG}";;
                        \?) error "unknown option '%s'\n" "${OPTARG}";;
                esac
        done
shift $((OPTIND-1))

if [ ! -f $ifile ]; then
        error "Please provide a JPG/BMP file(-i)\n"
fi
if [ -z "${ofile}" ]; then
        error "no output file specified (-o)\n"
fi

if [ -f $ofile ]; then
        rm $ofile
fi

#create header as per datastructure. 3 sizes required
append_binary4 3 $ofile
append_binary4 0 $ofile
append_binary4 0 $ofile
append_binary4 0 $ofile
append_binary4 3 $ofile
append_binary4 0 $ofile
append_binary4 0 $ofile
append_binary4 0 $ofile

#create binary format for 3 sizes
let logo_offset=1024
append_binary8 $logo_offset $ofile
append_header 1920 1080 $ofile

let logo_offset=$logo_offset+1920*1080*2
append_binary8 $logo_offset $ofile
append_header 1280 720 $ofile


let logo_offset=$logo_offset+1280*720*2
append_binary8 $logo_offset $ofile
append_header 640 480 $ofile

#append zeros to take align logo offset
append_zero 968 $ofile

#use ffmpeg to generate yuv files for 3 resolutions
ffmpeg -i $ifile -pix_fmt uyvy422 -s 1920x1080 -f rawvideo - | cat >> $ofile
ffmpeg -i $ifile -pix_fmt uyvy422 -s 1280x720 -f rawvideo - | cat >> $ofile
ffmpeg -i $ifile -pix_fmt uyvy422 -s 640x480 -f rawvideo - | cat >> $ofile

gzip $ofile
}

error() { local fmt="${1}"; shift; printf "ERROR: ${fmt}" "${@}"; exit 1; }

my_name="${0##*/}"
main "${@}"

