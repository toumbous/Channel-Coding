%This file compares channel codes which show the bit error probability within the system
%created by toumbous

clc;
clear all;

%%Design of transmitter
%random data source generate data between 0 to 1
data=randsrc(1,100,[0:0.1:1]);

%source coding
symbols=unique(data);
probabilities = histc(data,symbols)./numel(data);
[dict, avglen] = huffmandict(symbols, probabilities);
comp = huffmanenco(data,dict);

%different channel codings
% Convolutionally encoding data 
constlen=7;
codegen = [171 133];    % Polynomial
trellis = poly2trellis(constlen, codegen);
codedata = convenc(comp, trellis);

%BCH encoding of Data
if mod(size(comp,1),4)==0
    h=fec.bchenc(7,4);
    codedata1 = encode(h,comp');
else 
    le=mod(size(comp,1)*size(comp,2),4);
    le1=4-le;
    comp=[comp,zeros(1,le1)];
    h=fec.bchenc(7,4);
    codedata1=encode(h,comp');
end

%QAM Modulation
M=16;
Tx_data1=qammod(codedata,M);
Tx_data2=qammod(codedata1,M);

%%Channel
SNR=2;
p=1;
while SNR<=50 && p<=26
Rx_data1=awgn(Tx_data1,10,'measured');%AWGN channel with SNR=10db
Rx_data2=awgn(Tx_data2,10,'measured');

%Receiver
de_mod_data1=qamdemod(Rx_data1,M);%demodulation
de_mod_data2=qamdemod(Rx_data2,M);
dmod_data1=de2bi(de_mod_data1','left-msb');
dmod_data1=dmod_data1';
dmod_data2=de2bi(de_mod_data2','left-msb');

% dmod_data2=dmod_data2';
dmod_data1=reshape(dmod_data1,1,size(dmod_data1,1)*size(dmod_data1,2));
% dmod_data2=reshape(dmod_data2,1,size(dmod_data2,1)*size(dmod_data2,2));
decodedata =vitdec(dmod_data1,trellis,5,'trunc','hard');  % decoding datausing veterbi decoder
rxed_data1=decodedata;
h1= fec.bchdec(h);
decodedata1 = decode(h1,dmod_data2);
decodedata1 = decodedata1';
rxed_data2=decodedata1;
[num_error1(p),ratio1(p)]=biterr(comp,rxed_data1(1:length(comp)));
[num_error2(p),ratio2(p)]=biterr(comp,rxed_data2(1,:));
SNR=SNR+2;
p=p+1;
end

k=1:length(ratio1);
plot(k,ratio1,k,ratio2,'.-')
legend('Convolution code','Forward Error Correction Code');
xlabel('Signal Power');
ylabel('Bit Error Probability')
title('BER comparison')
