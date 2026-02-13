# Projeto de Big Data com AWS Glue, MWAA e Terraform

Este projeto implementa um pipeline de dados ponta-a-ponta na AWS, utilizando as melhores práticas de Infraestrutura como Código (IaC), automação e CI/CD.

A arquitetura é composta por:
- **Amazon S3:** Armazenamento de dados brutos (raw), processados (processed), scripts e DAGs.
- **AWS Glue:** Processamento e transformação de dados (ETL) com PySpark, otimizado para performance e resiliência.
- **Amazon MWAA (Managed Workflows for Apache Airflow):** Orquestração do pipeline de dados.
- **Terraform:** Provisionamento de toda a infraestrutura de forma automatizada e modular.
- **GitHub Actions:** Automação do deploy (CI/CD) para os ambientes de desenvolvimento e produção.

---

## Arquitetura

1.  **Ingestão:** Os dados de origem são depositados no bucket S3 de dados brutos, criado pelo Terraform.
2.  **Orquestração:** Uma DAG no ambiente MWAA é acionada (diariamente, por padrão).
3.  **Processamento:** A DAG aciona um Job no AWS Glue. O Terraform configura o job para passar dinamicamente os caminhos de S3 (entrada e saída) como argumentos para o script. O script PySpark lê os dados, aplica transformações e escreve o resultado em formato Parquet no bucket de dados processados.
4.  **Armazenamento:** Os dados processados e prontos para consumo ficam disponíveis no bucket S3 correspondente.

---

## Pré-requisitos (Configuração Manual)

Antes de executar o pipeline do GitHub Actions pela primeira vez, os seguintes recursos e configurações são necessários.

1.  **Bucket S3 para o State do Terraform:**
    - Crie um bucket S3 para armazenar o arquivo de estado (`.tfstate`). Ex: `meu-projeto-terraform-state-12345`.
    - Habilite o versionamento e a criptografia no bucket.

2.  **Tabela DynamoDB para State Locking:**
    - Crie uma tabela no DynamoDB para controlar o acesso concorrente ao arquivo de estado.
    - A chave primária (Partition key) deve ser `LockID` (do tipo String).

3.  **Atualizar `providers.tf`:**
    - Modifique o arquivo `terraform/providers.tf` com os nomes do bucket e da tabela que você acabou de criar.

    ```hcl
    // terraform/providers.tf
    backend "s3" {
      bucket         = "NOME-DO-SEU-BUCKET-DE-STATE" 
      key            = "bigdata-aws/terraform.tfstate"
      region         = "us-east-1"
      dynamodb_table = "NOME-DA-SUA-TABELA-DYNAMODB" 
      encrypt        = true
    }
    ```

4.  **IAM Role para GitHub Actions (OIDC):**
    - Configure um provedor OIDC no IAM da sua conta AWS para permitir a comunicação com o GitHub.
    - Crie uma IAM Role que o GitHub Actions possa assumir (`sts:AssumeRoleWithWebIdentity`).
    - Anexe a essa role as permissões necessárias para o Terraform criar os recursos (ex: `AdministratorAccess` para começar, ou permissões mais granulares para produção).
    - **Crie um Secret no GitHub:** Vá em `Settings > Secrets and variables > Actions` no seu repositório e crie um novo secret chamado `AWS_OIDC_ROLE_ARN` com o ARN da role que você criou.

---

## Estrutura de Diretórios

```
.
├── .github/workflows/      # Pipelines de CI/CD
├── terraform/              # Código da Infraestrutura
│   ├── modules/            # Módulos reutilizáveis (s3, glue, mwaa)
│   ├── environments/       # Arquivos de variáveis por ambiente (dev/prod)
│   └── ...
├── src/
│   ├── glue/jobs/          # Scripts PySpark para o AWS Glue
│   └── dags/               # DAGs do Airflow para o MWAA
└── README.md
```

---

## Pipeline de CI/CD (Aperfeiçoado)

O pipeline é definido em `.github/workflows/deploy.yml` e foi otimizado para ser mais robusto e dinâmico:

-   **Gatilho:** Ocorre em `push` nas branches `developer` e `main`.
-   **Lógica de Execução:**
    1.  **Configura o Ambiente:** Determina o ambiente (`dev` ou `prod`) com base na branch.
    2.  **Credenciais AWS:** Autentica-se na AWS de forma segura usando a Role OIDC configurada no secret `AWS_OIDC_ROLE_ARN`.
    3.  **Terraform Apply:** Executa `terraform init`, `plan` e `apply` para criar ou atualizar a infraestrutura.
    4.  **Extração de Outputs:** Após o `apply`, o pipeline executa `terraform output` para extrair dinamicamente os nomes dos buckets de scripts e DAGs que foram criados.
    5.  **Sincronização Inteligente:** Usa os nomes de bucket extraídos no passo anterior para sincronizar os scripts PySpark e as DAGs do Airflow para os locais corretos no S3. Este método elimina a necessidade de nomes "hardcoded" e garante que o pipeline funcione mesmo que a nomenclatura dos recursos seja alterada no Terraform.
