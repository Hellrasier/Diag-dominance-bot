from thevlang/vlang:alpine

WORKDIR /home/v

COPY . .

RUN v install dariotarantini.vgram
RUN v install vtl
RUN v diag_bot.v

CMD ["./diag_bot"]
