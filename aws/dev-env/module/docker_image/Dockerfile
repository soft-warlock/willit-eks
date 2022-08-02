FROM python:3.8
WORKDIR /app
COPY app /app
RUN ls -la
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN apt update -y
ENV FLASK_APP=time.py
EXPOSE 8080
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=8080"]
