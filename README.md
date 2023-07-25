# Sysadmin-ManuAlonso

Práctica sysadmin Manuel Alonso Jurado

# Instrucciones de Uso

El entorno se ha levantado usando Vagrant con VirtualBox

Para hacer uso del entorno se tiene que lanzar el comando "vagrant up" en la ruta donde se descargue el repo.

Esto levantara las maquinas server1 y server2:
    Se podra acceder al wordpress desde http://localhost:8081 y generar un blog.
        (https://github.com/manualonsoj/PracticaSysAdmin/blob/main/Imagenes/Wordpreesinicio.png)

    Para acceder a los logs tendremos que entrar en la web http://localhost:5601
        usuario:elastic
        pass: entrar a la maquina y revisar fichero /elastic.txt para revisar pass generado durante la instalacion
        #Imagen kibana

    Una vez logueados podremos generar un data view de Filebeat donde se podran ver los logs.
        #Imagen Data view con logs



