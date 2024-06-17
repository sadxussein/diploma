# Netology диплом
Помимо файлов конфигурации приведенных в репозитории, в bashrc юзера добавлены такие строки:
```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)

export TF_VAR_yandex_token=$(yc iam create-token)
export TF_VAR_cloud_id=$(yc config get cloud-id)
export TF_VAR_folder_id=$(yc config get folder-id)
export TF_VAR_yandex_profile="sa-terraform"
export TF_VAR_ssh_public_key_path="/home/xussein/.ssh/id_rsa_nopasswd.pub"
```
Также бастион сервер используется как http прокси. Можно вынести в отдельный сервер, но для экономии средств на yc было решено сделать одним.

Порядок создания инфраструктуры:
1. terraform apply (main.tf)
получаем ip бастиона, добавляем в bastion.ini и inventory.ini для ансибла
2. ansible-playbool -i bastion.ini bastion.yml
3. ansible-playbool -i inventory.ini nginx-filebeat.yml
4. ansible-playbool -i inventory.ini elasticsearch-logstash.yml
5. ansible-playbool -i inventory.ini kibana.yml
6. ansible-playbool -i inventory.ini zabbix.yml

После создания заббикса на всех хостах уже подготовлен агент. Нужно только добавить хосты и применить шаблоны. Дашборды тоже настроены вручную. 
В идеале (при наличии времени) можно доготовить плейбук под хосты/шаблоны/дашборды, заготовка под это уже есть в zabbix-add-hosts.yml