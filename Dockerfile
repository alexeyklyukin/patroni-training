FROM ubuntu:18.04

ADD bootstrap.sh /

RUN bash -x bootstrap.sh

ARG COMPRESS=false

RUN if  [ "$COMPRESS" = "true" ]; then \
        set -ex \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get install -y busybox xz-utils \
        && apt-get purge -y git \
        && apt-get autoremove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
                /var/cache/debconf/* \
                /root/.cache \
                /usr/share/doc \
                /usr/share/man \
                /usr/share/postgresql/*/man \
                /usr/share/locale/?? \
                /usr/share/locale/??_?? \
                /usr/share/info \
                /usr/lib/python3/dist-packages/setuptools/command/launcher* \
                /usr/lib/python3/dist-packages/setuptools/script* \
        && find /var/log -type f -exec truncate --size 0 {} \; \
        && find /usr/share/i18n/charmaps/ -type f ! -name UTF-8.gz -delete \
        && find /usr/share/i18n/locales/ -type f ! -name en_US -delete \
        && echo 'en_US.UTF-8 UTF-8' > /usr/share/i18n/SUPPORTED \
        && echo 'postgres ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \

        && cd / \
        && ln -snf busybox /bin/sh \
        && files="/bin/sh /usr/bin/sudo /usr/lib/sudo/sudoers.so /lib/x86_64-linux-gnu/security/pam_env.so /lib/x86_64-linux-gnu/security/pam_permit.so /lib/x86_64-linux-gnu/security/pam_unix.so" \
        && libs="$(ldd $files | awk '{print $3;}' | grep '^/' | sort -u) /lib/x86_64-linux-gnu/ld-linux-x86-64.so.* /lib/x86_64-linux-gnu/libnsl.so.* /lib/x86_64-linux-gnu/libnss_compat.so.*" \
        && (echo /var/run $files $libs | tr ' ' '\n' && realpath $files $libs) | sort -u | sed 's/^\///' > /exclude \
        && find /lib/x86_64-linux-gnu/security/ -type f >> /exclude \
        && find /etc/alternatives -xtype l -delete \
        && save_dirs="usr lib var bin sbin etc/ssl etc/init.d etc/alternatives etc/apt" \
        && XZ_OPT=-e9v tar -X /exclude -cpJf a.tar.xz $save_dirs \
        && /bin/busybox sh -c "(find $save_dirs -not -type d && cat /exclude /exclude && echo exclude) | sort | uniq -u | xargs /bin/busybox rm" \
        && /bin/busybox --install -s \
        && /bin/busybox sh -c "find $save_dirs -type d -depth -exec rmdir -p {} \; 2> /dev/null"; \
    fi

USER postgres

WORKDIR /var/lib/postgresql

ADD launch.sh /

CMD ["/bin/sh", "/launch.sh"]
