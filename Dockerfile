
# Use an official Python runtime as a parent image
FROM python:3.8


# Install all OS dependencies for fully functional instant client
RUN apt-get update -y \
	&& apt-get install vim -y \
	&& apt-get install -y --no-install-recommends  git \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* 


# Set the working directory
WORKDIR /app


COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN git clone https://github.com/CHUV-DS/RDF-i2b2-converter.git /app/RDF-i2b2-converter

CMD cd RDF-i2b2-converter \ 
    && git pull \
    && ls -la /config && ls -la /data \
    && python3 src/main_data.py

#ENTRYPOINT ["tail", "-f", "/dev/null"]

