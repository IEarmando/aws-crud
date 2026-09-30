Cloud-Native GitOps Infrastructure & Automation Lab

:pushpin: Descripción del Proyecto
Infraestructura como Código (IaC) de grado de producción y pipeline de integración y despliegue continuo (CI/CD) implementados en AWS bajo un modelo GitOps. El proyecto automatiza el aprovisionamiento de infraestructura pura y la configuración multi-entorno (dev, prod) de una aplicación web basada en PHP/Apache y bases de datos relacionales con contenedores Docker, garantizando una estricta separación de poderes entre Terraform (Infraestructura) y Ansible (Configuración y Despliegue).

:hammer_and_wrench: Stack Tecnológico

- Cloud & Redes: AWS (VPC con subredes públicas y privadas, tablas de ruta, Internet Gateway, EC2, Amazon RDS MySQL, IAM Roles & Policies, S3).
- IaC & Automatización: Terraform (v1.16.3), Ansible (Gestión de configuración orientada a roles y tareas modulares), GitHub Actions (GitOps workflow con planes automáticos y despliegues manuales bajo demanda).
- Contenedores & Orquestación: Docker, Docker Compose V2, Docker Buildx.
- Observabilidad & Monitoreo: Amazon CloudWatch Logs Insights (centralización de logs), CloudWatch Metrics & Alarms (CPUUtilization), y notificaciones automatizadas de despliegue vía Slack API.


:rocket: Características Principales y Logros Técnicos

- Arquitectura GitOps Multi-Entorno: Configuración de un pipeline robusto en GitHub Actions que ejecuta validaciones y planes automáticos, permitiendo despliegues controlados a dev y prod mediante aprobaciones manuales (workflow_dispatch).
- Separación de Poderes (Terraform + Ansible): Terraform se encarga exclusivamente de provisionar la infraestructura pura en AWS (redes, bases de datos y el cascarón de las instancias EC2 sin scripts embebidos), mientras que Ansible maneja de forma idempotente la configuración del sistema operativo, instalación segura de herramientas y despliegue de la app.
- Inventarios Dinámicos al Vuelo: Generación automatizada y dinámica de los hosts de conexión dentro del pipeline de GitHub Actions, permitiendo adaptarse de forma transparente a los cambios de IP pública de las instancias EC2 tras cada ciclo de vida.
- Despliegues Seguros y Automatizados: Empaquetado de artefactos de la aplicación hacia S3, descarga en tiempo real en los servidores mediante AWS CLI, inyección dinámica de secretos productivos a través de GitHub Secrets hacia archivos .env, y levantamiento orquestado con Docker Compose.
- Observabilidad y Alertas Proactivas: Integración de logs hacia CloudWatch y creación de alarmas nativas para supervisar umbrales críticos de rendimiento del procesador (CPUUtilization).
