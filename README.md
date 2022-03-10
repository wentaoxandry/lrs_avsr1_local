# LRS dataset processing
This repository is for espnet/egs/lrs/avsr1 local folder. Detailed information please see [espnet](https://github.com/wentaoxandry/espnet/tree/master/egs/lrs) lrs/avsr1 repository

* data_prepare: prepare lrs2 and lrs3 dataset for audio-visual speech recognition
* dump: re-creat dump files for audio-visual speech recognition and split dump files according to their signal-to-noise ratio (SNR)
* extract_reliability: do audio and visual data augmentation. Extract the reliability measures based on the paper "Fusing information streams in end-to-end audio-visual speech recognition." (https://ieeexplore.ieee.org/document/9414553) [[1]](#literature)
* training: the files for audio-visual speech recognition. ESPnet is designed for audio-only speech recognition. Therefore, we changed some codes to fit the audio-visual task. In the training process, we create a link to the ESPnet environment and train the model. After training, these links will be released. The ESPnet code will not be changed. 

***
### Literature

[1] W. Yu, S. Zeiler and D. Kolossa, "Fusing Information Streams in End-to-End Audio-Visual Speech Recognition," ICASSP 2021 - 2021 IEEE International Conference on Acoustics, Speech and Signal Processing (ICASSP), 2021, pp. 3430-3434, doi: 10.1109/ICASSP39728.2021.9414553.
