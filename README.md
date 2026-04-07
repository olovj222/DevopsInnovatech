# Devops Innovatech - Infraestructura con Terraform

Este proyecto contiene la configuración de infraestructura como código (IaC) para el despliegue de recursos en **AWS**, desarrollado como parte de un laboratorio universitario.

## Requisitos Previos

Antes de comenzar, asegúrate de tener instalado lo siguiente en el computador :

* **Terraform** (v1.0 o superior)
* **Git Bash** (recomendado para Windows)
* **AWS CLI** configurado con las credenciales de **AWS Academy**.

## Estructura del Proyecto

* `terraform.tf`: Archivo principal con la configuración de proveedores y recursos.
* `/infra`: Carpeta que contiene módulos o archivos adicionales de configuración.
* `.gitignore`: Filtro para evitar subir archivos temporales y estados de Terraform.
* `.terraform.lock.hcl`: Garantiza que se usen las mismas versiones de los proveedores.

##  Pasos para el Despliegue

Sigue este orden en la terminal al descargar el repositorio:

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/olovj222/DevopsInnovatech.git](https://github.com/olovj222/DevopsInnovatech.git)
    cd DevopsInnovatech
    ```

2.  **Inicializar Terraform:**
    *(Esto descargará los proveedores de AWS definidos en el archivo lock)*
    ```bash
    terraform init
    ```

3.  **Validar las credenciales de AWS:**
    ```bash
    aws configure
    ```

4.  **Ver el plan de ejecución:**
    ```bash
    terraform plan
    ```

5.  **Aplicar los cambios:**
    ```bash
    terraform apply
    ```

## Script Terraform

Este repositorio contiene la configuración de Terraform para desplegar una arquitectura web escalable y segura en AWS. El diseño separa los componentes en subredes públicas y privadas para maximizar la seguridad.

##  Arquitectura Desplegada

El script `terraform.tf` crea los siguientes recursos en la región `us-east-1`:

### 1. Redes y Conectividad (VPC)
* **VPC Principal**: Segmento de red `10.0.0.0/16`.
* **Subred Pública**: Para el servidor Frontend (`10.0.1.0/24`).
* **Subred Privada**: Para Backend y Base de Datos (`10.0.2.0/24`).
* **NAT Gateway**: Permite que las instancias en la subred privada tengan salida a internet para actualizaciones sin ser accesibles desde fuera.

### 2. Seguridad (Security Groups)
El grupo de seguridad `sg_multicapa` gestiona el tráfico mediante reglas específicas:
* **Puerto 22 (SSH)**: Acceso administrativo abierto.
* **Puerto 80 (HTTP)**: Acceso web público para el Frontend.
* **Puerto 8080**: Tráfico al Backend permitido solo desde la subred pública.
* **Puerto 3306 (MySQL)**: Acceso a la base de datos permitido solo desde la subred privada.

### 3. Instancias (EC2)
Se utilizan instancias `t2.micro` basadas en una plantilla de lanzamiento (`launch_template`):
* **Frontend**: Instalación automática de **Nginx** y **Docker**.
* **Backend**: Configurado con **Java 17** y **Docker** para ejecutar aplicaciones Spring Boot.
* **Database**: Servidor **MySQL** preconfigurado.

## Cómo usar este repositorio

1.  **Inicializar**: `terraform init`
2.  **Planificar**: `terraform plan`
3.  **Desplegar**: `terraform apply`

## Salidas (Outputs)
Al finalizar, Terraform te entregará las direcciones IP necesarias para la conexión:
* `ip_frontend`: IP pública para ver tu aplicación.
* `ip_backend_privada`: IP interna para que el frontend se comunique con el backend.
* `ip_database_privada`: IP interna para la conexión a MySQL.

---
*Nota: Este proyecto utiliza el perfil `LabInstanceProfile` compatible con **AWS Academy**.* 
## Notas Importantes (AWS Academy)

Recuerda que las credenciales de AWS Academy son temporales. Asegúrate de actualizar tu archivo `~/.aws/credentials` o exportar las variables de entorno antes de ejecutar `terraform plan` para evitar errores de autenticación.

---
© 2026 - Proyecto Universitario de Introducción a Herramientas DevOps