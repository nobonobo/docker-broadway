FROM alpine:3.12 AS build

RUN apk add -U alpine-sdk
ENV username="alpine" useremail="alpine@example.org" loginuser="alpine"
RUN adduser -D $username && addgroup $username abuild && echo "$username ALL=(ALL) ALL" >> /etc/sudoers
RUN mkdir -p /var/cache/distfiles \
    && chgrp abuild /var/cache/distfiles \
    && chmod g+w /var/cache/distfiles \
    && echo "PACKAGER='$username <$useremail>'" >> /etc/abuild.conf
USER $loginuser
WORKDIR /home/$loginuser
RUN su $loginuser; cd; \
    git config --global user.name '$username' && \
    git config --global user.email '$useremail' && \
    abuild-keygen -a -i
RUN mkdir -p aport
WORKDIR /home/$loginuser/aport
RUN git init && git config core.sparsecheckout true
RUN git remote add origin https://git.alpinelinux.org/cgit/aports
RUN echo main/gtk+3.0/ > .git/info/sparse-checkout
RUN git pull origin master
WORKDIR /home/$loginuser/aport/main/gtk+3.0
RUN sed -i 's|--enable-x11-backend|--enable-x11-backend --enable-broadway-backend|' APKBUILD
RUN abuild -r

FROM alpine:3.12

RUN apk add -U --no-cache curl fontconfig xfdesktop xfce4 \
    && curl -O https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
    && mkdir -p /usr/share/fonts/NotoSansCJKjp \
    && unzip NotoSansCJKjp-hinted.zip -d /usr/share/fonts/NotoSansCJKjp/ \
    && rm NotoSansCJKjp-hinted.zip \
    && fc-cache -fv
COPY  --from=build /home/alpine/packages /packages
RUN apk add --allow-untrusted /packages/main/x86_64/*.apk
ENV GDK_BACKEND=broadway BROADWAY_DISPLAY=:0
EXPOSE 8080
