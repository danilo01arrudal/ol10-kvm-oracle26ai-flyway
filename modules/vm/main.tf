# Geração do arquivo kickstart a partir do template
resource "local_file" "ks" {
  content = templatefile("${path.module}/templates/ks.cfg.tpl", {
    ip                  = var.ip
    gateway             = var.gateway
    netmask             = var.netmask
    dns                 = var.dns
    hostname            = var.hostname
    disk_size_mb        = var.disk_size_mb
    root_size_mb        = local.root_size_mb
    swap_size_mb        = var.swap_size_mb
    timezone            = var.timezone
    root_password_hash  = var.root_password_hash
    user_name           = var.user_name
    user_password_hash  = var.user_password_hash
  })
  filename = "${path.module}/../../data/kickstart/${local.ks_filename}"
}

# Recurso principal que executa o virt-install
resource "null_resource" "vm" {
  triggers = {
    vm_name      = var.name
    memory       = var.memory
    vcpus        = var.vcpus
    disk_path    = var.disk_path
    disk_size_gb = var.disk_size_gb
    iso_path     = var.iso_path
    ip           = var.ip
    network      = var.network
    ks_filename  = local.ks_filename
    ks_content   = local_file.ks.content
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e # Aborta a execução se qualquer comando falhar

      LOG_DIR="${path.module}/../../data/logs"
      LOG_FILE="$LOG_DIR/install-${self.triggers.vm_name}.log"

      # Garante a existência do diretório de logs
      mkdir -p "$LOG_DIR"

      echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Iniciando provisionamento da VM ${self.triggers.vm_name} ===" | tee "$LOG_FILE"

      # Cria diretório para o disco se não existir e remove disco anterior
      mkdir -p "$(dirname ${self.triggers.disk_path})"
      rm -f "${self.triggers.disk_path}"

      # Executa a instalação registrando saída e erros no log
      if virt-install \
        --virt-type kvm \
        --name "${self.triggers.vm_name}" \
        --memory "${self.triggers.memory}" \
        --vcpus "${self.triggers.vcpus}" \
        --os-variant ol8.10 \
        --location "${self.triggers.iso_path}" \
        --network "network=${self.triggers.network},model=virtio" \
        --disk "path=${self.triggers.disk_path},size=${self.triggers.disk_size_gb}" \
        --initrd-inject "${local_file.ks.filename}" \
        --extra-args "inst.ks=file:/${self.triggers.ks_filename} console=tty0 console=ttyS0,115200" \
        --noautoconsole >> "$LOG_FILE" 2>&1; then

        echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] VM ${self.triggers.vm_name} disparada com sucesso. ===" | tee -a "$LOG_FILE"
      else
        EXIT_CODE=$?
        echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] ERRO FATAL: Falha ao executar virt-install (Exit code $EXIT_CODE). ===" | tee -a "$LOG_FILE"
        echo "Consulte os detalhes do erro em: $LOG_FILE" >&2
        exit $EXIT_CODE
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Destruindo VM ${self.triggers.vm_name}..."
      virsh destroy ${self.triggers.vm_name} 2>/dev/null || true
      virsh undefine ${self.triggers.vm_name} --remove-all-storage 2>/dev/null || true
      rm -f ${self.triggers.disk_path}
      echo "VM removida."
    EOT
  }
}

# ============================================================
# Aguarda a instalação terminar e inicia a VM automaticamente
# ============================================================
resource "null_resource" "start_vm" {
  depends_on = [null_resource.vm]

  triggers = {
    vm_name = var.name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      VM_NAME="${self.triggers.vm_name}"
      LOG_DIR="${path.module}/../../data/logs"
      LOG_FILE="$LOG_DIR/start-${VM_NAME}.log"
      mkdir -p "$LOG_DIR"

      echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Aguardando instalação da VM $VM_NAME finalizar ===" | tee -a "$LOG_FILE"

      # 1. Aguarda a VM aparecer no libvirt (máximo ~10 minutos)
      for i in $(seq 1 60); do
        if virsh dominfo "$VM_NAME" &>/dev/null; then
          echo "VM $VM_NAME encontrada no libvirt." | tee -a "$LOG_FILE"
          break
        fi
        echo "Aguardando VM aparecer... ($i/60)" | tee -a "$LOG_FILE"
        sleep 10
      done

      if ! virsh dominfo "$VM_NAME" &>/dev/null; then
        echo "ERRO: VM $VM_NAME não foi criada." | tee -a "$LOG_FILE"
        exit 1
      fi

      # 2. Aguarda a VM ficar em estado shut off (instalação + reboot concluídos)
      echo "Aguardando VM entrar em estado 'shut off'..." | tee -a "$LOG_FILE"
      for i in $(seq 1 90); do
        STATE=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
        echo "Estado atual: $STATE ($i/90)" | tee -a "$LOG_FILE"

        if [ "$STATE" = "shut off" ]; then
          echo "VM está em 'shut off'. Aguardando 30 segundos de segurança..." | tee -a "$LOG_FILE"
          sleep 30
          break
        fi

        if [ "$STATE" = "running" ]; then
          echo "VM já está running. Nada a fazer." | tee -a "$LOG_FILE"
          exit 0
        fi

        sleep 10
      done

      # 3. Inicia a VM
      echo "Iniciando VM $VM_NAME..." | tee -a "$LOG_FILE"
      virsh start "$VM_NAME"

      # 4. Confirma que ficou running
      sleep 5
      FINAL_STATE=$(virsh domstate "$VM_NAME")
      if [ "$FINAL_STATE" = "running" ]; then
        echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] VM $VM_NAME iniciada com sucesso ===" | tee -a "$LOG_FILE"
      else
        echo "ERRO: Falha ao iniciar a VM. Estado final: $FINAL_STATE" | tee -a "$LOG_FILE"
        exit 1
      fi
    EOT
  }
}
