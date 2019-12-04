#!/usr/bin/env bash

# check the enviroment info
nvidia-smi
PYTHON="/root/miniconda3/bin/python"
${PYTHON} -m pip install yacs
${PYTHON} -m pip install torchcontrib

export PYTHONPATH="/msravcshare/yuyua/code/segmentation/openseg.pytorch":$PYTHONPATH

cd ../../

DATA_DIR="/msravcshare/dataset/mapillary-vista-v1.1"
SAVE_DIR="/msravcshare/dataset/seg_result/mapillary/"
BACKBONE="hrnet48"
CONFIGS="configs/mapillary/${BACKBONE}.json"

MAX_ITERS=100000
BATCH_SIZE=16

MODEL_NAME="hrnet48_ocr"
LOSS_TYPE="fs_auxce_loss"
CHECKPOINTS_NAME="${MODEL_NAME}_mapillary_bs${BATCH_SIZE}_${MAX_ITERS}_ft_"$2
LOG_FILE="./log/mapillary/${CHECKPOINTS_NAME}.log"
PRETRAINED_MODEL="./pretrained_model/hrnetv2_w48_imagenet_pretrained.pth"

PRETRAINED_MODEL="./checkpoints/mapillary/hrnet48_ocr_mapillary_bs16_200000_2_max_performance.pth"

export lambda_poly_power=0

if [ "$1"x == "train"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} \
                       --drop_last y \
                       --train_batch_size ${BATCH_SIZE} \
                       --include_val y \
                       --base_lr 0.0001 \
                       --phase train \
                       --gathered n \
                       --loss_balance y \
                       --log_to_file n \
                       --backbone ${BACKBONE} \
                       --model_name ${MODEL_NAME} \
                       --gpu 0 1 2 3 \
                       --data_dir ${DATA_DIR} \
                       --loss_type ${LOSS_TYPE} \
                       --max_iters ${MAX_ITERS} \
                       --resume ${PRETRAINED_MODEL} \
                       --resume_strict False \
                       --resume_eval_train False \
                       --checkpoints_name ${CHECKPOINTS_NAME} \
                       --test_interval 10000 \
                       > ${LOG_FILE} 2>&1
                       

elif [ "$1"x == "resume"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y --train_batch_size ${BATCH_SIZE} \
                       --phase train --gathered n --loss_balance y --log_to_file n \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --max_iters ${MAX_ITERS} \
                       --data_dir ${DATA_DIR} --loss_type ${LOSS_TYPE} --gpu 0 1 2 3 \
                       --resume_continue y --resume ./checkpoints/mapillary/${CHECKPOINTS_NAME}_latest.pth \
                       --checkpoints_name ${CHECKPOINTS_NAME} \
                       --test_interval 10000 \
                       >> ${LOG_FILE} 2>&1


elif [ "$1"x == "debug"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y \
                       --phase debug --gpu 0 --log_to_file n  > ${LOG_FILE} 2>&1


elif [ "$1"x == "val"x ]; then
  # ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y \
  #                      --backbone ${BACKBONE} --model_name ${MODEL_NAME} --checkpoints_name ${CHECKPOINTS_NAME} \
  #                      --phase test --gpu 0 1 2 3 --resume ./checkpoints/mapillary/${CHECKPOINTS_NAME}_latest.pth \
  #                      --loss_type ${LOSS_TYPE} --test_dir ${DATA_DIR}/val/image \
  #                      --out_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val 
  # hrnet48_hrnet48__8_80000_1_val

  cd lib/metrics
  ${PYTHON} -u cityscapes_evaluator.py --pred_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val/label  \
                                       --gt_dir ${DATA_DIR}/val/label_edge_void_20


elif [ "$1"x == "test"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --checkpoints_name ${CHECKPOINTS_NAME} \
                       --phase test --gpu 0 --resume ./checkpoints/mapillary/${CHECKPOINTS_NAME}_latest.pth \
                       --test_dir ${DATA_DIR}/test --log_to_file n --out_dir test >> ${LOG_FILE} 2>&1

else
  echo "$1"x" is invalid..."
fi
