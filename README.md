# Provisionamento Automatizado de VMs Oracle Linux 8.10 com Terraform em ambiente on-premisse servidor KVM Oracle Linux 10 Instalando o Oracle Database 26ai e a ferrramenta Flyway possibilitando a execucao de scripts de deploy de schema de forma automatica.

[![GitHub](https://img.shields.io/badge/Repository-danilo01arrudal/ol10--kvm--oracle26ai--flyway-blue?logo=github)](https://github.com/danilo01arrudal/ol10-kvm-oracle26ai-flyway)
[![Terraform](https://img.shields.io/badge/Terraform-≥1.5-purple?logo=terraform)](https://www.terraform.io/)
[![Oracle Linux](https://img.shields.io/badge/Oracle%20Linux-8.10%20%2B%2010-red?logo=oracle)](https://www.oracle.com/linux/)
[![Oracle Database](https://img.shields.io/badge/Oracle%20Database-26ai%20EE-orange?logo=oracle)](https://www.oracle.com/database/)
[![Flyway](https://img.shields.io/badge/Flyway-Migration-green?logo=flyway)](https://flywaydb.org/)
[![KVM](https://img.shields.io/badge/KVM-libvirt-blue?logo=qemu)](https://www.linux-kvm.org/)

## Visão Geral

Este projeto automatiza, de ponta a ponta, a criação de uma máquina virtual Oracle Linux 8.10 em ambiente KVM/libvirt (host Oracle Linux 10) e, após a instalação do sistema operacional, realiza:

1. Criação da VM **Oracle Linux 8.10** no KVM  
1. Instalação do **Oracle Database 26ai Enterprise Edition** (via RPM)
2. Criação de um banco de dados (CDB + PDB)
3. Instalação do **Flyway**
4. Execução automática de scripts de migration (ex.: schema **HR**)

Tudo isso controlado pelo Terraform, de forma **reprodutível**, **configurável** e **desassistida**.

### Objetivos principais

- **Reprodutível**: todo o processo (OS + Database + Flyway) é descrito como código.
- **Automatizado**: instalação do SO via Kickstart + pós-instalação via scripts remotos.
- **Modular**: lógica de VM isolada em módulo reutilizável.
- **Extensível**: fácil adicionar novos schemas ou migrations via Flyway.
- **Integrável**: pode ser usado em pipelines CI/CD.

## Principais Funcionalidades

| Funcionalidade                        | Descrição                                                                 |
|---------------------------------------|---------------------------------------------------------------------------|
| Criação automatizada de VMs           | Provisiona VMs KVM com `virt-install`                                     |
| Instalação desassistida do SO         | Kickstart gerado dinamicamente a partir de template                       |
| Rede estática                         | IP, gateway, máscara e DNS configuráveis                                  |
| Particionamento flexível              | LVM com volumes root e swap parametrizados                                |
| Instalação Oracle Database 26ai EE    | Via RPM + script de criação de banco (CDB + PDB)                          |
| Instalação e configuração do Flyway   | Download + configuração automática                                        |
| Deploy de schema via Flyway           | Execução de migrations (exemplo: schema HR)                               |
| Ciclo de vida completo                | `terraform apply` / `terraform destroy`                                   |
| Segurança                             | Senhas com hash SHA-512 + suporte a chave SSH                             |
| Separação por ambiente                | Diretórios `dev` / `hom` / `prd`                                          |

## Fluxo de Execução

```
1. terraform apply
   ├── Gera Kickstart
   ├── Cria VM com virt-install (instalação OL 8.10)
   ├── Aguarda reboot + SSH disponível
   ├── Copia scripts e artefatos (RPM, Flyway, migrations)
   ├── Instala oracle-ai-database-preinstall-26ai + RPM 26ai EE
   ├── Cria banco de dados (CDB + PDB)
   ├── Instala e configura Flyway
   └── Executa flyway migrate (schema HR)
2. VM pronta para uso com Oracle Database + schema HR
```

## 🗂️ Estrutura do Projeto

```plaintext
ol10-kvm-oracle26ai-flyway/
├── README.md
├── LICENSE
├── .gitignore
├── terraform.tfvars.example
├── versions.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── modules/
│   └── vm/
│       ├── variables.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── templates/
│           └── ks.cfg.tpl
├── data/
│   ├── kickstart/                  # Kickstarts gerados
│   ├── oracle/                     # RPM, scripts de instalação Oracle + Flyway
│   │   ├── 01-preinstall.sh
│   │   ├── 02-install-rpm.sh
│   │   ├── 03-create-database.sh
│   │   ├── 04-install-flyway.sh
│   │   ├── 05-flyway-hr.sh
│   │   └── ...
│   ├── flyway/                     # Migrations e configuração Flyway
│   │   └── sql/
│   │       ├── V1__create_hr_schema.sql
│   │       └── V2__populate_hr.sql
│   └── scripts/
│       └── generate-hash.sh
├── environments/
│   ├── dev/
│   ├── hom/
│   └── prd/
├── docs/
│   ├── architecture.md
│   └── troubleshooting.md
└── images/
```

## ⚙️ Tecnologias Utilizadas

| Tecnologia              | Versão / Observação          | Finalidade                                      |
|-------------------------|------------------------------|-------------------------------------------------|
| Oracle Linux            | 10 (host) / 8.10 (guest)     | SO do host e da VM                              |
| KVM / libvirt           | —                            | Hipervisor                                      |
| Terraform               | ≥ 1.5                        | Infrastructure as Code                          |
| virt-install            | —                            | Criação da VM                                   |
| Oracle Database         | 26ai Enterprise Edition      | Banco de dados                                  |
| oracle-ai-database-preinstall-26ai | —                  | Pré-requisitos do Oracle                        |
| Flyway                  | Community (última estável)   | Controle de versão de schema / migrations       |
| Java                    | 17 ou 21 (OpenJDK)           | Runtime do Flyway                               |

## ✅ Pré-requisitos

### 1. Host (Oracle Linux 10)

- Virtualização por hardware habilitada (`vmx` ou `svm`)
- Pacotes:
  ```bash
  sudo dnf install -y qemu-kvm libvirt virt-install openssl openssh-clients
  ```
- Terraform instalado
- Serviço `libvirtd` ativo
- Usuário no grupo `libvirt` e `kvm`
- Rede `default` do libvirt ativa
- Espaço em disco suficiente (≥ 100 GB livres recomendado)

### 2. Artefatos necessários (no host)

Antes de executar o Terraform, baixe e coloque nos locais corretos:

| Artefato                                      | Local sugerido                          |
|-----------------------------------------------|-----------------------------------------|
| ISO Oracle Linux 8.10                         | `/var/lib/libvirt/images/`              |
| RPM `oracle-ai-database-ee-26ai-*.el8.x86_64.rpm` | `data/oracle/`                       |
| Flyway (zip) + driver JDBC Oracle             | `data/oracle/` ou baixado automaticamente pelos scripts |

### 3. Recursos mínimos recomendados para a VM

| Recurso     | Valor mínimo | Valor recomendado |
|-------------|--------------|-------------------|
| Memória     | 8 GB         | 16 GB             |
| vCPUs       | 4            | 8                 |
| Disco       | 80 GB        | 100–150 GB        |
| Swap        | 8 GB         | 16 GB             |

## 🚀 Como Utilizar

### 1. Clonar o repositório

```bash
git clone https://github.com/danilo01arrudal/ol10-kvm-oracle26ai-flyway.git
cd ol10-kvm-oracle26ai-flyway
```

### 2. Preparar artefatos

- Coloque o RPM do Oracle Database 26ai EE em `data/oracle/`
- (Opcional) Coloque o zip do Flyway ou deixe o script baixar automaticamente

### 3. Configurar variáveis

```bash
cp terraform.tfvars.example terraform.tfvars
# ou
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Edite pelo menos:

- `vm_config.name`
- `vm_config.ip`
- `vm_config.iso_path`
- `vm_config.disk_path`
- `vm_config.memory` / `vcpus` / `disk_size_gb`
- `root_password_hash` e `user_password_hash`
- `db_password` (SYS/SYSTEM)
- `hr_password` (usuário HR)

**Gerar hash de senha:**

```bash
./data/scripts/generate-hash.sh "SuaSenhaForte123"
# ou
openssl passwd -6 "SuaSenhaForte123"
```

### 4. Inicializar e aplicar

```bash
terraform init
terraform plan
terraform apply
```

O processo completo (criação da VM + instalação do SO + Oracle + Flyway + schema HR) pode levar de **25 a 50 minutos**, dependendo do hardware e da velocidade de download.

### 5. Acompanhar a instalação

```bash
# Console da VM
virsh console <nome_da_vm>

# Logs de pós-instalação (após SSH ficar disponível)
ssh admin@<IP> "sudo tail -f /var/log/oracle-install/*.log"
```

### 6. Verificar o resultado

Após o `terraform apply` concluir com sucesso:

```bash
ssh admin@<IP>

# Como usuário oracle
sudo su - oracle
sqlplus / as sysdba

# Verificar PDB e schema HR
SHOW PDBS;
ALTER SESSION SET CONTAINER = ORCLPDB1;
SELECT username FROM dba_users WHERE username = 'HR';
```

Flyway:

```bash
/opt/flyway/flyway info
```

### 7. Destruir o ambiente

```bash
terraform destroy
```

Remove a VM, o disco e os arquivos gerados.

## 🌍 Ambientes

O projeto suporta múltiplos ambientes:

```bash
cd environments/dev
terraform init
terraform apply
```

Cada ambiente possui seu próprio `terraform.tfvars`.

## 🔧 Personalização

- **Schema adicional**: adicione novas migrations em `data/flyway/sql/`
- **Parâmetros do banco**: edite o script `03-create-database.sh` (SID, PDB, character set, memória, etc.)
- **Particionamento**: ajuste o template `ks.cfg.tpl`
- **Recursos da VM**: altere `memory`, `vcpus` e `disk_size_gb` no `terraform.tfvars`

## 📚 Documentação Adicional

- [docs/architecture.md](docs/architecture.md) – Arquitetura detalhada
- [docs/troubleshooting.md](docs/troubleshooting.md) – Problemas comuns e soluções

## Referências

- [Oracle AI Database 26ai Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/26/)
- [Oracle Database Sample Schemas (HR)](https://github.com/oracle-samples/db-sample-schemas)
- [Flyway Documentation](https://documentation.red-gate.com/flyway)
- [Oracle Linux Kickstart](https://docs.oracle.com/en/operating-systems/oracle-linux/)

---

**Autor:** Danilo Arruda  
**Licença:** MIT (ou a que estiver definida no repositório)
