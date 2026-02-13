# Projeto de Big Data com AWS Glue, MWAA e Terraform

Este projeto implementa um pipeline de dados ponta-a-ponta na AWS, utilizando as melhores práticas de Infraestrutura como Código (IaC) e CI/CD.

A arquitetura é composta por:
- **Amazon S3:** Armazenamento de dados brutos (raw), processados (processed), scripts e DAGs.
- **AWS Glue:** Processamento e transformação de dados (ETL) com PySpark, otimizado para performance e resiliência.
- **Amazon MWAA (Managed Workflows for Apache Airflow):** Orquestração do pipeline de dados.
- **Terraform:** Provisionamento de toda a infraestrutura de forma automatizada e modular.
- **GitHub Actions:** Automação do deploy (CI/CD) para os ambientes de desenvolvimento e produção.

---

## Arquitetura

1.  **Ingestão:** Os dados de origem são depositados no bucket S3 `...-raw-...`.
2.  **Orquestração:** Uma DAG no ambiente MWAA é acionada (diariamente, por padrão).
3.  **Processamento:** A DAG aciona um Job no AWS Glue. O script PySpark lê os dados do bucket raw, aplica transformações e otimizações (como Adaptive Query Execution), e escreve o resultado em formato Parquet no bucket `...-processed-...`.
4.  **Armazenamento:** Os dados processados e prontos para consumo ficam disponíveis no bucket `...-processed-...`.

---

## Pré-requisitos (Configuração Manual)

Antes de executar o pipeline do GitHub Actions pela primeira vez, os seguintes recursos devem ser criados manualmente na AWS. Eles são necessários para o `backend` do Terraform funcionar corretamente.

1.  **Bucket S3 para o State do Terraform:**
    - Crie um bucket S3 para armazenar o arquivo de estado (`.tfstate`). Ex: `meu-projeto-terraform-state-12345`.
    - Habilite o versionamento e a criptografia no bucket.

2.  **Tabela DynamoDB para State Locking:**
    - Crie uma tabela no DynamoDB para controlar o acesso concorrente ao arquivo de estado.
    - A chave primária (Partition key) deve ser `LockID` (do tipo String).

3.  **Atualizar `providers.tf`:**
    - Modifique o arquivo `terraform/providers.tf` com os nomes do bucket e da tabela que você acabou de criar.

    ```hcl
    backend "s3" {
      bucket         = "NOME-DO-SEU-BUCKET-DE-STATE" // <-- Substitua aqui
      key            = "bigdata-aws/terraform.tfstate"
      region         = "us-east-1"
      dynamodb_table = "NOME-DA-SUA-TABELA-DYNAMODB" // <-- Substitua aqui
      encrypt        = true
    }
    ```

4.  **IAM Role para GitHub Actions (OIDC):**
    - Configure um provedor OIDC no IAM da sua conta AWS para permitir a comunicação com o GitHub.
    - Crie uma IAM Role que o GitHub Actions possa assumir (`sts:AssumeRoleWithWebIdentity`).
    - Anexe a essa role as permissões necessárias para o Terraform criar os recursos (ex: `AdministratorAccess` para começar, ou permissões mais granulares para produção).
    - Atualize o arquivo `.github/workflows/deploy.yml` com o ARN da role criada.

---

## Estrutura de Diretórios

```
.
├── .github/workflows/      # Pipelines de CI/CD
├── terraform/              # Código da Infraestrutura
│   ├── modules/            # Módulos reutilizáveis (s3, glue, mwaa)
│   ├── environments/       # Arquivos de variáveis por ambiente (dev/prod)
│   ├── main.tf             # Orquestração principal dos módulos
│   └── ...
├── src/
│   ├── glue/jobs/          # Scripts PySpark para o AWS Glue
│   └── dags/               # DAGs do Airflow para o MWAA
└── README.md
```

---

## Pipeline de CI/CD

O pipeline é definido em `.github/workflows/deploy.yml` e funciona da seguinte maneira:

-   **Push na branch `developer`:**
    1.  Configura as credenciais da AWS via OIDC.
    2.  Executa `terraform init`, `plan` e `apply` utilizando o arquivo `environments/dev/terraform.tfvars`.
    3.  Infraestrutura do ambiente de **desenvolvimento** é criada/atualizada.
    4.  Scripts de `src/glue/jobs` e `src/dags` são sincronizados com os buckets S3 de `dev`.

-   **Push na branch `main`:**
    1.  Configura as credenciais da AWS via OIDC.
    2.  Executa `terraform init`, `plan` e `apply` utilizando o arquivo `environments/prod/terraform.tfvars`.
    3.  Infraestrutura do ambiente de **produção** é criada/atualizada.
    4.  Scripts de `src/glue/jobs` e `src/dags` são sincronizados com os buckets S3 de `prod`.
# bigdata-with-aws
