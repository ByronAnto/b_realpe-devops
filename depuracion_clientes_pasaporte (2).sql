--192.168.101.74
--use MAXPOINT_R006;

IF OBJECT_ID('tempdb..##clientesD') IS NOT NULL
drop table ##clientesD
CREATE TABLE ##clientesD (ci varchar(200), total varchar(200));
--VALIDAR SEA CORRECTO EL RUC Y CI VALIDOS -- DE IGUAL FORMA VALIDAR LA FECHA DE CREACION SELECIONAR LA MAS ACTUAL 
insert ##clientesD
select cli_documento , COUNT(*) from cliente c  --where cli_documento='1700359647001' 
inner join Tipo_Documento t on t.IDTipoDocumento = c.IDTipoDocumento
where t.tpdoc_descripcion in ('PASAPORTE')
group by c.cli_documento
having COUNT(*)>1
order by 1
 
IF exists(
select top(1) 1 from ##clientesD
)
BEGIN
	declare
	@contadorinterno AS INT = 1,
	@numerodetalle AS INT = (SELECT count(*) FROM ##clientesD)
	WHILE (@contadorinterno <= @numerodetalle)
	begin
		declare @ci_actual varchar(120),
				@idclientecorrecto varchar(120);
		set @ci_actual = (SELECT ci
											  FROM ( SELECT  *, 
														ROW_NUMBER() OVER ( ORDER BY ci ) AS pivote  
														FROM ##clientesD  WITH (NOLOCK)
												   ) AS tb_detalle
												 WHERE tb_detalle.pivote = @contadorinterno)



		IF exists(
		select top(1) 1 from Cliente where (cli_nombres != '' and cli_nombres is not null)
										  and (cli_telefono != '' or cli_telefono is not null)
										  and (cli_direccion != '' or cli_direccion is not null)
										  and (cli_email != '' and cli_email is not null) and cli_documento = @ci_actual
		)
		BEGIN
			set @idclientecorrecto = (select TOP(1) IDCliente from Cliente C
										  inner join Tipo_Documento t on t.IDTipoDocumento = c.IDTipoDocumento 
										  where (cli_nombres != '' and cli_nombres is not null)
										  and (cli_telefono != '' or cli_telefono is not null)
										  and (cli_direccion != '' or cli_direccion is not null)
										  and (cli_email != '' and cli_email is not null) and cli_documento = @ci_actual
										  order by FechaActualizacion desc)
		END
		ELSE
		BEGIN
			set @idclientecorrecto = (select TOP(1) IDCliente from Cliente C
										  inner join Tipo_Documento t on t.IDTipoDocumento = c.IDTipoDocumento 
										  where (cli_nombres != '' and cli_nombres is not null)
										  and (cli_telefono != '' or cli_telefono is not null)
										  and (cli_direccion != '' or cli_direccion is not null)
										  and (cli_email != '' OR cli_email is not null) and cli_documento = @ci_actual 
										  order by FechaActualizacion desc)
		END

	IF OBJECT_ID('tempdb..##clientesMalos') IS NOT NULL
	drop table ##clientesMalos
	CREATE TABLE ##clientesMalos (idCliente varchar(200));

	INSERT INTO ##clientesMalos
	select IDCliente from Cliente where cli_documento = @ci_actual and IDCliente != @idclientecorrecto;

		--CAMBIO DE DATOS PARA FACTURAS
			IF exists(
			SELECT top(1) 1 FROM Cabecera_Factura WHERE IDCliente IN (SELECT IDCliente FROM ##clientesMalos)
			)
			BEGIN
			--VALIDAR QUE EL STATUS ESTE ENTREGADA
				--ACTUALIZA FACTURAS
				update Cabecera_Factura set IDCliente=@idclientecorrecto  WHERE IDCliente IN (SELECT IDCliente FROM ##clientesMalos) 
			END
		--CAMBIO DE DATOS PARA NOTAS DE CREDITO
			IF exists(
			SELECT top(1) 1 FROM Cabecera_Nota_Credito WHERE IDCliente IN (SELECT IDCliente FROM ##clientesMalos)
			)
			BEGIN
				--ACTUALIZA LAS NC
				update Cabecera_Nota_Credito set IDCliente=@idclientecorrecto  WHERE IDCliente IN (SELECT IDCliente FROM ##clientesMalos) 
			END
		--CLIENTE ELIMINADOS
	delete Cliente where IDCliente IN (SELECT IDCliente FROM ##clientesMalos); 

	SET @contadorinterno = @contadorinterno + 1 ;
	END
	select cli_documento , COUNT(*) from cliente c  --where cli_documento='1700359647001' 
	inner join Tipo_Documento t on t.IDTipoDocumento = c.IDTipoDocumento
	where t.tpdoc_descripcion in ('PASAPORTE')
	group by c.cli_documento
	having COUNT(*)>1
	order by 1
 
	SELECT 'TABLA CLIENTE DEPURADA'
END
ELSE
BEGIN
	select cli_documento , COUNT(*) from cliente c  --where cli_documento='1700359647001' 
	inner join Tipo_Documento t on t.IDTipoDocumento = c.IDTipoDocumento
	where t.tpdoc_descripcion in ('PASAPORTE')
	group by c.cli_documento
	having COUNT(*)>1
	order by 1
 
	SELECT 'TABLA CLIENTE DEPURADA'
	SELECT 'NO EXISTE CLIENTE DUPLICADOS '
END
