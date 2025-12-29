# Ragstar: AI Data Analyst for dbt Projects

**Previously known as dbt-llm-agent**

Ragstar is an AI agent that learns the context of your dbt project to answer questions, generate documentation, and bring data insights closer to your users. Interact via Slack or CLI, and watch it improve over time with feedback.

**BETA NOTICE**: Ragstar is currently in beta. Core features include agentic model interpretation and semantic question answering about your dbt project.

## Table of Contents

- Key Value
- Key Features
- Use Cases
- Architecture
- Setup
  - Option 1: Docker Compose (Recommended)
  - Option 2: Local Python Environment (Advanced)
- Usage
  - Using Docker Compose
  - Using Local Python Environment
  - Core Commands
- Configuration
- Performance Optimizations
- Security Considerations
- Slack Integration (Optional)
- Contributing
- License

## Key Value

- **Democratize Data Access:** Allow anyone to ask questions about your dbt project in natural language via Slack or CLI.
- **Automate Documentation:** Generate model and column descriptions where they're missing, improving data catalog quality.
- **Enhance Data Discovery:** Quickly find relevant models and understand their logic without digging through code.
- **Continuous Learning:** Ragstar learns from feedback to provide increasingly accurate and helpful answers.

## Key Features

- **Natural Language Q&A**: Ask about models, sources, metrics, lineage, etc.
- **Agentic Interpretation**: Intelligently analyzes dbt models, understanding logic and context.
- **Automated Documentation Generation**: Fills documentation gaps using LLMs.
- **Semantic Search**: Finds relevant assets based on meaning, not just keywords.
- **dbt Integration**: Parses metadata from dbt Cloud, local runs (manifest.json), or source code.
- **Postgres + pgvector Backend**: Stores metadata and embeddings efficiently.
- **Feedback Loop**: Tracks questions and feedback for improvement.
- **Slack Integration**: Built-in Slackbot for easy interaction.

## Use Cases

- **Accelerate Data Discovery**: Quickly find relevant dbt models and understand their purpose without digging through code.
- **Improve Onboarding**: Help new team members understand the dbt project structure and logic faster.
- **Maintain Data Documentation**: Keep dbt documentation up-to-date with automated generation and suggestions.
- **Enhance Data Governance**: Gain better visibility into data lineage and model dependencies.
- **Debug dbt Models**: Ask clarifying questions about model logic and calculations.

## Architecture

Ragstar combines several technologies to provide its capabilities:

- **dbt Project Parsing**: Extracts comprehensive metadata from dbt artifacts (manifest.json) or source files (.sql, .yml), including models, sources, exposures, metrics, tests, columns, descriptions, and lineage.
- **PostgreSQL Database with pgvector**: Serves as the central knowledge store. It holds structured metadata parsed from the dbt project, generated documentation, question/answer history, and vector embeddings of model and column descriptions for semantic search.
- **Vector Embeddings**: Creates numerical representations (embeddings) of model and column documentation using sentence-transformer models. These embeddings capture semantic meaning, enabling powerful search capabilities.
- **Large Language Models (LLMs)**: Integrates with LLMs (e.g., OpenAI's GPT models) via APIs to:
  - Understand natural language questions.
  - Generate human-readable answers based on retrieved context from the database and embeddings.
  - Interpret model logic and generate documentation.
- **Agentic Reasoning**: Employs a step-by-step reasoning process, especially for model interpretation, where it breaks down the task, gathers evidence (e.g., upstream model definitions), and synthesizes an interpretation, similar to how a human analyst would approach it.
- **CLI Interface**: Provides command-line tools (ragstar ...) for initialization, embedding generation, asking questions, providing feedback, and managing the system.

## Setup

Setting up Ragstar involves configuring environment variables and initializing the application with your dbt project data. The recommended method is using Docker Compose, which bundles the application and a PostgreSQL database with the required pgvector extension.

### Option 1: Docker Compose (Recommended)

1. **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd ragstar
    ```

2. **Set up environment variables:**
    Rename `.env.example` to `.env` and populate it with your specific configurations, such as your OpenAI API key and the `APP_HOST` (e.g., `localhost` or your server's IP address).

    ```bash
    cp .env.example .env
    # Open .env and fill in your values
    ```

    Required environment variables:
    - `LLM_OPENAI_API_KEY`: Your OpenAI API key (or other LLM provider keys)
    - `APP_HOST`: Host address for the application
    - `SECRET_KEY`: Django secret key (generate a secure random string for production)
    - `DEBUG`: Set to `false` for production, `true` for development

3. **Configure Ragstar rules:**
    Rename `.ragstarrules.example.yml` to `.ragstarrules.yml`. This file allows you to define custom instructions and behaviors for your RAG application.

    ```bash
    cp .ragstarrules.example.yml .ragstarrules.yml
    # Open .ragstarrules.yml and customize if needed
    ```

4. **Build and run with Docker Compose:**
    This command will build the Docker images and start the application in detached mode.

    ```bash
    docker compose up --build -d
    ```

5. **Run initial Django commands:**
    Execute these commands in the `app` container to set up the database and create an admin user.

    ```bash
    docker compose exec app uv run python manage.py migrate
    docker compose exec app uv run python manage.py createsuperuser
    # Follow prompts to create your admin user
    ```

6. **Initialize your project:**
    This command sets up the necessary project configurations. You can choose between `cloud`, `core`, or `local` methods.

    ```bash
    docker compose exec app uv run python manage.py init_project --method cloud
    # Or --method core, or --method local
    ```

7. **Access the Django Admin:**
    Open your web browser and navigate to `http://<your_APP_HOST_value>/admin` (e.g., `http://localhost/admin` if `APP_HOST=localhost`).
    Log in with the superuser credentials you created.

8. **Embed Models:**
    In the Django admin interface, you can:
    - Navigate to "Models".
    - Click on "Interpret".
    - Select and embed the models you want to use for answering questions.

### Option 2: Local Python Environment (Advanced)

If you prefer not to use Docker, you can set up a local Python environment.

1. **Prerequisites:**

    - Python 3.10 or higher.
    - `uv` (Python package installer and virtual environment manager).
    - A running PostgreSQL server (version 11+) with the `pgvector` extension enabled.

2. **Check Python Version:**

    ```bash
    python --version # or python3 --version
    ```

3. **Clone Repository:**

    ```bash
    git clone <repository-url>
    cd ragstar
    ```

4. **Create a virtual environment and install dependencies:**

    ```bash
    # Create a virtual environment (e.g., named .venv)
    python -m venv .venv
    # Or using uv: uv venv

    # Activate the virtual environment
    source .venv/bin/activate # On Windows: .venv\Scripts\activate

    # Install dependencies using uv
    uv pip install -r requirements.txt
    # Or if you have a pyproject.toml configured for uv:
    # uv pip install -e .
    ```

5. **Set up PostgreSQL:**

    - Install PostgreSQL and `pgvector`.
    - Create a database (e.g., `ragstar_local_dev`).
    - Enable the `pgvector` extension in the database:
      ```sql
      -- Run in psql connected to your database
      CREATE EXTENSION IF NOT EXISTS vector;
      ```

6. **Configure Environment Variables:**
    Copy the example environment file and fill in your details:

    ```bash
    cp .env.example .env
    ```

    Edit `.env`:

    - **Required:** Set your `LLM_OPENAI_API_KEY` (or other LLM provider keys).
    - **Required:** Set `DATABASE_URL` to your local PostgreSQL connection string (e.g., `postgresql://user:password@host:port/dbname`). Ensure this matches the database you created.
    - **Required:** Set `APP_HOST` (e.g., `localhost` or `127.0.0.1`).
    - **Required:** Set `SECRET_KEY` to a secure random string (generate one for production).
    - **Required:** Set `DEBUG` to `false` for production, `true` for development.
    - **Ragstar Rules:** Rename `.ragstarrules.example.yml` to `.ragstarrules.yml` and customize if needed.
    - **Slack (Optional):** Configure `INTEGRATIONS_SLACK_BOT_TOKEN` and `INTEGRATIONS_SLACK_SIGNING_SECRET` if you plan to use the Slack integration.
    - **CORS (Optional):** Set `CORS_ALLOWED_ORIGINS` as a comma-separated list of allowed origins (e.g., `http://localhost:3000,https://example.com`). If not set and DEBUG is true, all origins are allowed.
    - **Other:** Review other variables like `RAGSTAR_LOG_LEVEL`, etc., and adjust if needed.

7. **Run Database Migrations:**
    Apply database schema changes:

    ```bash
    uv run python manage.py migrate
    ```

8. **Create a Superuser:**
    Create an admin account to access the Django admin interface:

    ```bash
    uv run python manage.py createsuperuser
    # Follow the prompts
    ```

9. **Initialize your project:**
    This command sets up the necessary project configurations.

    ```bash
    uv run python manage.py init_project --method cloud
    # Or --method core, or --method local, depending on your dbt project setup.
    ```

10. **Initialize your project (for `dbt` core):**
    If you use `dbt` core you might need to set up adapters first. Sample below for PostgreSQL.

    ```bash
    uv pip install dbt-core dbt-postgres
    uv run python manage.py init_project --method core
    ```

11. **Run the Development Server:**

    ```bash
    uv run python manage.py runserver
    ```

    The application will typically be available at `http://<your_APP_HOST_value>:8000` (e.g., `http://localhost:8000`).

12. **Access the Django Admin & Embed Models:**
    Follow the same steps as in the Docker setup (steps 7 and 8) to access the admin interface (`http://<your_APP_HOST_value>:8000/admin`) and embed your models.

## Usage

After setup and initialization, you can interact with Ragstar.

### Using Docker Compose:

Most Django `manage.py` commands should be run **inside the `app` container** using `docker compose exec`:

```bash
# Example: Run database migrations (if not already done by entrypoint)
docker compose exec app uv run python manage.py migrate

# Example: Create a superuser (if not done during initial setup)
docker compose exec app uv run python manage.py createsuperuser

# Example: Initialize project
docker compose exec app uv run python manage.py init_project --method cloud
```

The application server is started automatically by `docker compose up`. Access it via `http://<your_APP_HOST_value>/admin`.

### Using Local Python Environment:

Run Django `manage.py` commands directly using `uv run` from your activated virtual environment:

```bash
# Example: Run the development server
uv run python manage.py runserver

# Example: Create a superuser
uv run python manage.py createsuperuser

# Example: Initialize project
uv run python manage.py init_project --method cloud
```

Access the application at `http://<your_APP_HOST_value>:8000` and the admin interface at `http://<your_APP_HOST_value>:8000/admin`.

### Core Django Management Commands

The primary way to manage and interact with the application (outside of the web interface) is through Django's `manage.py` script. Here are some key commands:

- **`uv run python manage.py migrate`**: Applies database migrations.
- **`uv run python manage.py createsuperuser`**: Creates an administrator account.
- **`uv run python manage.py init_project --method <cloud|core|local>`**: Initializes Ragstar with your project data (e.g., from dbt). This is crucial for setting up the knowledge base.
- **`uv run python manage.py runserver [host:port]`**: Starts the Django development web server.

Other functionalities, such as interpreting and embedding models, are primarily handled through the Django admin interface after logging in.

## Configuration

### Environment Variables

Key environment variables for configuration:

- **LLM Configuration:**
  - `LLM_OPENAI_API_KEY`: OpenAI API key
  - `LLM_GOOGLE_API_KEY`: Google API key (optional)
  - `LLM_ANTHROPIC_API_KEY`: Anthropic API key (optional)
  - `LLM_CHAT_PROVIDER_NAME`: Chat provider (openai, google, anthropic) - default: openai
  - `LLM_CHAT_MODEL`: Chat model name - default: o4-mini
  - `LLM_EMBEDDINGS_PROVIDER_NAME`: Embeddings provider (openai, google) - default: openai
  - `LLM_EMBEDDINGS_MODEL`: Embeddings model name - default: text-embedding-3-small
  - `LLM_CHAT_CONFIG_TEMPERATURE`: Temperature for chat model (optional)

- **Database:**
  - `DATABASE_URL`: PostgreSQL connection string
  - `DB_NAME_FALLBACK`: Fallback database name (if DATABASE_URL not set)
  - `DB_USER_FALLBACK`: Fallback database user
  - `DB_PASSWORD_FALLBACK`: Fallback database password
  - `DB_HOST_FALLBACK`: Fallback database host
  - `DB_PORT_FALLBACK`: Fallback database port
  - `DB_SSL_REQUIRE`: Require SSL for database connection (true/false)

- **Application:**
  - `APP_HOST`: Application host address
  - `APP_PORT`: Application port - default: 8000
  - `SECRET_KEY`: Django secret key (REQUIRED for production)
  - `DEBUG`: Debug mode (true/false) - default: false
  - `CORS_ALLOWED_ORIGINS`: Comma-separated list of allowed CORS origins

- **Logging:**
  - `SETTINGS_LOG_LEVEL`: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL) - default: INFO

- **Slack Integration (Optional):**
  - `INTEGRATIONS_SLACK_BOT_TOKEN`: Slack bot token
  - `INTEGRATIONS_SLACK_SIGNING_SECRET`: Slack signing secret

## Performance Optimizations

Ragstar includes several performance optimizations:

- **Batch Embedding Processing**: The embedding service uses batch processing when available, significantly improving performance when generating embeddings for multiple texts simultaneously.

- **Multi-stage Docker Build**: The Dockerfile uses a multi-stage build process to create smaller, more efficient container images by separating build dependencies from runtime dependencies.

- **Database Query Optimization**: The application uses Django's `select_related` and `prefetch_related` where appropriate to minimize database queries and improve response times.

- **Connection Pooling**: Database connections are pooled efficiently to reduce connection overhead.

- **Caching Strategy**: Static files are served efficiently using WhiteNoise middleware with compression.

## Security Considerations

- **Secret Key Management**: Always set `SECRET_KEY` as an environment variable in production. Never commit secret keys to version control.

- **Debug Mode**: Set `DEBUG=false` in production to prevent sensitive information leakage.

- **CORS Configuration**: Configure `CORS_ALLOWED_ORIGINS` explicitly in production. Only allow specific trusted origins rather than using wildcards.

- **Database Security**: Use SSL connections for production databases by setting `DB_SSL_REQUIRE=true`.

- **API Keys**: Store all API keys securely as environment variables and never expose them in logs or error messages.

- **Allowed Hosts**: Configure `ALLOWED_HOSTS` appropriately for your deployment environment.

## Slack Integration (Optional)

Ragstar provides a Slack manifest to easily integrate its functionalities into your Slack workspace.

1. Ensure `INTEGRATIONS_SLACK_SIGNING_SECRET` and `INTEGRATIONS_SLACK_BOT_TOKEN` are set in your `.env` file.
2. Use the `.slack_manifest.example.json` file as a template to create a new Slack app.
3. Follow Slack's documentation for creating an app from a manifest.
4. This will enable features like asking questions and receiving answers directly within Slack (assuming the Slack integration is running as part of the Django application).

## Contributing

Contributions are welcome! Please follow standard fork-and-pull-request workflow.

## License

MIT License
