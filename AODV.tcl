# Projeto de redes sem fio - AODV

# Opcoes
set val(chan)		Channel/WirelessChannel		;# Tipo de canal
set val(prop)		Propagation/TwoRayGround    ;# Propagacao
set val(netif)		Phy/WirelessPhy		    	;# Tipo de interface de rede
set val(mac)		Mac/802_11		    		;# Tipo do MAC
set val(ifq)		Queue/DropTail/PriQueue     ;# Tipo de fila
set val(ll)			LL			    			;# Link Layer
set val(ant)		Antenna/OmniAntenna	  	 	;# Tipo de antena
set val(ifqlen)		50						 	;# Numero máximo de pacotes
set val(pckSize)   	512                         ;# Tamanho do pacote
set val(nn)			48			    			;# Numero de nos moveis
set val(rp)			AODV		    		    ;# Protocolo de roteamento
set val(x)			500			    			;# Dimensao X
set val(y)			500			    			;# Dimensao Y
set val(speed)     	12                         	;# Velocidade de movimento dos nos
set val(stop)		100 		    			;# Tempo de simulacao

set ns		        [new Simulator]
set tracefd	    	[open testAODV.tr w]
set windowVsTime2  	[open win.tr w]
set namtrace	    [open testAODV.nam w]

$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

#Configura a topografia
set topo      [new Topography]

$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)

#
# Cria nn nos moveis [$val(nn)] e adiciona ao canal.
#

# Configura os nos
$ns node-config -adhocRouting $val(rp) \
	-llType $val(ll) \
	-macType $val(mac) \
	-ifqType $val(ifq) \
	-ifqLen $val(ifqlen) \
	-antType $val(ant) \
	-propType $val(prop) \
	-phyType $val(netif) \
	-channelType $val(chan) \
	-topoInstance $topo \
	-agentTrace ON \
	-routerTrace ON \
	-macTrace OFF \
	-movementTrace ON

# Cria todos os nos e colocam na posicao 0
for {set i 0} {$i < $val(nn) } { incr i } {
	set node_($i) [$ns node]
	$node_($i) set X_ 0.0
	$node_($i) set Y_ 0.0
	$node_($i) set Z_ 0.0
}

# Define posicoes aleatorias
for {set i 0} {$i < $val(nn) } { incr i } {
	set xx [expr rand()*500]
	set yy [expr rand()*500]
	$node_($i) set X_ $xx
	$node_($i) set Y_ $yy
}

# Define a posicao inicial do No no nam
for {set i 0} {$i < $val(nn)} { incr i } {
# 30 define o tamanho do no para nam
$ns initial_node_pos $node_($i) 30
}

# Informa aos Nos quando a simulacao Termina
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$node_($i) reset";
}

# Processo que gera um destino dinamico ate o termino do tempo.
$ns at 0.0 "destination"
proc destination {} {
      global ns val node_ 
      set time 10.0
      set now [$ns now]
      for {set i 0} {$i<$val(nn)} {incr i} {
            set xx [expr rand()*500]
            set yy [expr rand()*500]
            $ns at $now "$node_($i) setdest $xx $yy $val(speed)"
      }
      $ns at [expr $now+$time] "destination"
}

# Configura o CBR sobre o UDP
# Realiza um laço de repeticao onde metade dos nos irao transmitir e metade receber
for {set i 0} {$i < [expr $val(nn)/2]} {incr i} {
	
	# Seta metade dos nos como destino
    set dest [expr [expr $val(nn)/2]+$i]
	
    # Define um novo agente UDP
	set udp [new Agent/UDP]
	
	# Conecta o agente UDP ao no na posicao i
    $ns attach-agent $node_($i) $udp
	
	# Define um novo agente NULL
    set null [new Agent/Null]
	
	# Conecta o agente NULL ao no destino
    $ns attach-agent $node_($dest) $null
	
	# Conecta os dois agentes
    $ns connect $udp $null
	
	# Define um agente (CBR - Constant Bit Reate)
    set cbr [new Application/Traffic/CBR]
	
	# Conecta a agente CBR ao agente UDP
    $cbr attach-agent $udp
	
	# Seta o tamanho do Pacote
    $cbr set packetSize_ $val(pckSize)
	
	# Seta o tamanho do intervalo
    $cbr set interval_ 0.1
    $ns at 1.0 "$cbr start"
    $ns at [expr $val(stop)-5] "$cbr stop"
}


# Finalizando o nam e a simulacao
$ns at [expr $val(stop)] "$ns nam-end-wireless $val(stop)"
$ns at [expr $val(stop)+10] "stop"
$ns at [expr $val(stop)+20] "puts \"end simulation\" ; $ns halt"

proc stop {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
# Gera o arquivo com o PDR gerado
    exec awk -f Packet_Delivery_Ratio.awk testAODV.tr > outputAODV_1_16.tr &
}

$ns run
