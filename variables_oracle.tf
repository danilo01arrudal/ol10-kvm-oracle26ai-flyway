# ============================================================
# Oracle Database 26ai - Variáveis
# ============================================================

variable "oracle_password" {
  description = "Senha do usuário sistema operacional 'oracle'"
  type        = string
  sensitive   = true
}

variable "sys_password" {
  description = "Senha do usuário SYS"
  type        = string
  sensitive   = true
}

variable "system_password" {
  description = "Senha do usuário SYSTEM"
  type        = string
  sensitive   = true
}

variable "pdbadmin_password" {
  description = "Senha do usuário PDBADMIN"
  type        = string
  sensitive   = true
}

variable "dbsnmp_password" {
  description = "Senha do usuário DBSNMP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_sid" {
  description = "ORACLE_SID / nome do CDB"
  type        = string
  default     = "appscdb"
}

variable "pdb_name" {
  description = "Nome do PDB"
  type        = string
  default     = "appspdb1"
}

variable "oracle_home_version" {
  description = "Versão usada no caminho do ORACLE_HOME (ex: 23.26.1)"
  type        = string
  default     = "23.26.1"
}

variable "oracle_software_zip" {
  description = "Nome do arquivo zip do software Oracle Database"
  type        = string
  default     = "V1054592-01.zip"
}
