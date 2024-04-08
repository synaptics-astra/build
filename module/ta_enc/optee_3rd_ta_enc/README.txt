1. To get single ${ta_name}.cert:
    run   : ./gen_ta_cert.sh ${ta_path}/${ta_name}.ta
    output: ${ta_path}/ta_enc/${ta_name}.cert

2. To get single encrypted ta:
    run   : ./gen_full_ta_img.sh ${ta_nmae}.ta
    output: ${ta_path}/ta_enc/${ta_name}.ta

3. To get all encrypted ta:
    run   : ./optee_3rd_ta_enc.sh ${ta_path} [$ta_outpath]
    output: no ${ta_outpath}:   ${ta_path}/ta_enc/
            have ${ta_outpath}: ${ta_outpath}/
