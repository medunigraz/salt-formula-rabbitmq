{%- from "rabbitmq/map.jinja" import server with context %}
{%- if server.enabled %}

rabbitmq_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

rabbitmq_config:
  file.managed:
  - name: {{ server.config_file }}
  - source: salt://rabbitmq/files/rabbitmq.config
  - template: jinja
  - user: rabbitmq
  - group: rabbitmq
  - mode: 440
  - require:
    - pkg: rabbitmq_packages

{%- if grains.os_family == 'Debian' %}

rabbitmq_default_config:
  file.managed:
  - name: {{ server.default_file }}
  - source: salt://rabbitmq/files/default
  - template: jinja
  - user: rabbitmq
  - group: rabbitmq
  - mode: 440
  - require:
    - pkg: rabbitmq_packages

{%- endif %}

{%- if server.secret_key is defined %}

{%- if salt['cmd.run']('cat '+server.cookie_file) != server.secret_key %}

sleep_before_rabbitmq_stop:
  cmd.run:
  - name: sleep 30
  - user: root
  - require:
    - pkg: rabbitmq_packages
    - file: rabbitmq_config
{#    - cmd: enable_mgmt_plugin #}

stop_rabbitmq_service:
  cmd.run:
  - name: /etc/init.d/rabbitmq-server stop
  - require:
    - cmd: sleep_before_rabbitmq_stop

/var/lib/rabbitmq:
  file.directory

rabbitmq_cookie:
  file.managed:
  - name: {{ server.cookie_file }}
  - contents: {{ server.secret_key }}
  - user: rabbitmq
  - group: rabbitmq
  - mode: 400
  - require:
    - file: /var/lib/rabbitmq
    - cmd: stop_rabbitmq_service

{%- if grains.os_family == 'Arch' %}

/root/.erlang.cookie:
  file.managed:
  - contents: {{ server.secret_key }}
  - user: root
  - group: root
  - mode: 400

{%- endif %}

sleep_before_rabbitmq_start:
  cmd.run:
  - name: sleep 30
  - user: root
  - require:
    - cmd: stop_rabbitmq_service
  - watch_in:
    - service: rabbitmq_service

{%- endif %}

{%- endif %}

rabbitmq_service:
  service.running:
  - enable: true
  - name: {{ server.service }}
  - watch:
    - file: rabbitmq_config

{%- endif %}
