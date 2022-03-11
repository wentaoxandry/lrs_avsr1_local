#!/bin/bash


# Copyright 2021 Ruhr University Bochum (Wentao Yu)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)


# general configuration
backend=pytorch			# set backend type
ngpu=1         			# number of gpus ("0" uses cpu, otherwise use gpu)
debugmode=1
N=0            			# number of minibatches to be used (mainly for debugging). "0" uses all minibatches.
verbose=0      			# verbose option
nbpe=500
bpemode=unigram
nj=32
do_delta=false

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh


# parameter handover
expdir=$1
dumpdecodedir=$2
lmexpdir=$3
dict=$4
bpemodel=$5


resume=	      # Resume the training from snapshot


preprocess_config=conf/specaug.yaml
lm_config=conf/lm.yaml
decode_config=conf/decode.yaml


# decoding parameter
recog_model=model.last10.avg.best # set a model to be used for decoding: 'model.acc.best' or 'model.loss.best'
n_average=10


. utils/parse_options.sh || exit 1;

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

recog_evalset="-12 -9 -6 -3 0 3 6 9 12 clean reverb"
#recog_evalset="0"

#### The features should already extracted and the language model should be already trained

if [ ! -d $expdir ]; then
    mkdir -p ${expdir}
fi


# Replace files with custom files
rm -rf $MAIN_ROOT/espnet/finetuneav  || exit 1;
ln -rsf  local/training/finetuneav ${MAIN_ROOT}/espnet/finetuneav  || exit 1;
ln -rsf  local/training/finetuneav/e2e_asr_transformerdecode.py ${MAIN_ROOT}/espnet/finetuneav/e2e_asr_transformer.py  || exit 1;
rm -rf $MAIN_ROOT/espnet/bin/asr_train_avrms.py   || exit 1;
ln -rsf  local/training/finetuneav/asr_train_avrms.py $MAIN_ROOT/espnet/bin/asr_train_avrms.py   || exit 1;
rm -rf $MAIN_ROOT/espnet/bin/asr_recog_avrms.py  || exit 1;
ln -rsf  local/training/finetuneav/asr_recog_avrms.py $MAIN_ROOT/espnet/bin/asr_recog_avrms.py  || exit 1;



echo "stage 1: Decoding"
for noisetype in noise music blur saltandpepper; do
#for noisetype in saltandpepper; do
    rm -rf ${expdir}/$noisetype
    mkdir ${expdir}/$noisetype 
    for rtask in $recog_evalset; do   ####################### the file you want to decode
        pids=() # initialize pids
        (decode_dir=decode_${rtask}_$(basename ${decode_config%.*})
         feat_recog_dir=${dumpdecodedir}/Test_${noisetype}/${rtask}/delta${do_delta}

         # split data
         splitjson.py --parts ${nj} ${feat_recog_dir}/data_${bpemode}${nbpe}.json  || exit 1;

         #### use CPU for decoding
         ngpu=0
        ${decode_cmd} JOB=1:${nj} ${expdir}/${decode_dir}/log/decode.JOB.log \
            asr_recog_avrms.py \
            --config ${decode_config} \
            --ngpu ${ngpu} \
            --backend ${backend} \
            --debugmode ${debugmode} \
            --verbose 1 \
            --recog-json ${feat_recog_dir}/split${nj}utt/data_${bpemode}${nbpe}.JOB.json \
            --result-label ${expdir}/${decode_dir}/data.JOB.json \
            --model ${expdir}/${recog_model}  \
            --rnnlm ${lmexpdir}/rnnlm.model.best  || exit 1;

        score_sclite.sh --bpe ${nbpe} --bpemodel ${bpemodel}.model --wer true ${expdir}/${decode_dir} ${dict}  || exit 1;
        mv ${expdir}/${decode_dir} ${expdir}/$noisetype/${decode_dir}
         ) &
         pids+=($!) # store background pids

    
        i=0; for pid in "${pids[@]}"; do wait ${pid} || ((++i)); done
        [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
    
        echo "Finished"
     done
done
rm -rf $MAIN_ROOT/espnet/finetuneav  || exit 1;
rm -rf $MAIN_ROOT/espnet/bin/asr_train_avrms.py   || exit 1;
rm -rf $MAIN_ROOT/espnet/bin/asr_recog_avrms.py  || exit 1;

exit 0

