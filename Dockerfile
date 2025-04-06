FROM python:3.10-bookworm

ENV POETRY_VENV=/app/.venv
ENV PATH="${POETRY_VENV}/bin:${PATH}"

# Устанавливаем Rust и нужные пакеты
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libsndfile1-dev \
    ffmpeg \
 && curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="/root/.cargo/bin:$PATH"

RUN python3 -m venv $POETRY_VENV \
 && $POETRY_VENV/bin/pip install -U pip setuptools \
 && $POETRY_VENV/bin/pip install poetry==2.1.1

ENV PATH="${POETRY_VENV}/bin:$PATH"

# Устанавливаем проблемные зависимости заранее
RUN pip install torch==2.0.1+cpu torchaudio==2.0.2+cpu \
    -f https://download.pytorch.org/whl/cpu/torch_stable.html \
 && pip install tokenizers==0.13.3

WORKDIR /app
COPY . /app

RUN poetry config virtualenvs.in-project true
RUN poetry install --no-interaction --only main --no-root -vvv

# Swagger и ffmpeg
COPY --from=onerahmet/ffmpeg:n7.1 /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=swaggerapi/swagger-ui:v5.9.1 /usr/share/nginx/html/swagger-ui.css swagger-ui-assets/swagger-ui.css
COPY --from=swaggerapi/swagger-ui:v5.9.1 /usr/share/nginx/html/swagger-ui-bundle.js swagger-ui-assets/swagger-ui-bundle.js

EXPOSE 9000

ENTRYPOINT ["whisper-asr-webservice"]
