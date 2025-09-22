# Usar imagen base oficial de Python
FROM python:3.11-slim

# Configurar directorio de trabajo
WORKDIR /app

# Copiar requerimientos
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copiar la app
COPY . .

# Exponer puerto de Cloud Run
EXPOSE 8080

# Comando para ejecutar la app
CMD ["python", "app.py"]
