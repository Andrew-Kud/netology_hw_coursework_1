# Домашнее задание к занятию "`Курсовая работа на профессии "DevOps-инженер с нуля"`" - `Кудряшов Андрей`

---

Оснавная задача - разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных.
Согласно заданию: https://github.com/netology-code/fops-sysadm-diplom/blob/main/README.md

Условия:
* Инфраструктура должна размещаться в Yandex Cloud. 
* Мониторинг будет осуществляться при помощи Prometheus.
* Развёртывание инфраструктуры будет производиться при помощи Terraform и Ansible.
* Сбор и визуализация логов - ELK.
* Должена быть ВМ Bastion для ssh управления.

---

## Этап 1: Terraform

Этапы создания инфраструктуры:
https://docs.google.com/document/d/1P5oxvzPCOwivDtUC_eOXqr6bg8z3JbDDaJ_FwJa9pSo/edit?usp=sharing

Схема:
<img width="970" height="1064" alt="terra_3" src="https://github.com/user-attachments/assets/d2deed61-74fe-4fc5-ae2d-422171c9ca20" />


Результаты:
До terraform apply.
<img width="2560" height="865" alt="terra_1" src="https://github.com/user-attachments/assets/d775f9c8-004b-4767-a614-349c65c7f526" />

После terraform apply.
<img width="2554" height="1434" alt="terra_2" src="https://github.com/user-attachments/assets/60d75543-1388-41a1-a489-652ba27ecd70" />

PS: Часть комментраиев и объяснений оставил прямо в коде Terrafor, что бы не раздувать объяснения.

---
