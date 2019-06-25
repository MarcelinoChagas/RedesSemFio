# Projeto de redes sem fio - DSR

# Opcoes
set val(chan)		Channel/WirelessChannel		;# Tipo de canal
set val(prop)		Propagation/TwoRayGround    ;# Propagacao
set val(netif)		Phy/WirelessPhy		    	;# Tipo de interface de rede

set val(mac)		Mac/802_11		    		;# Tipo do MAC
set val(ifq)		Queue/DropTail/PriQueue     ;# Tipo de fila
set val(ll)			LL			    			;# Link Layer
set val(ant)		Antenna/OmniAntenna	  	 	;# Tipo de antena
set val(ifqlen)		900000000000			 	;# Numero máximo de pacotes
set val(pckSize)   	512                         ;# Tamanho do pacote
set val(nn)			16			    			;# Numero de nos moveis
set val(rp)			DSR		    		    	;# Protocolo de roteamento
set val(x)			500			    			;# Dimensao X
set val(y)			500			    			;# Dimensao Y
set val(speed)     	2                          ;# Velocidade de movimento dos nos
set val(stop)		100 		    			;# Tempo de simulacao

set ns		        [new Simulator]
set tracefd	    [open testDSR.tr w]
set windowVsTime2  [open win.tr w]
set namtrace	    [open testDSR.nam w]

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

# Define posicoes aleatorias
for {set i 0} {$i < $val(nn) } { incr i } {
	set node_($i) [$ns node]
	$node_($i) set X_ [ expr 10+round(rand()*480) ]
	$node_($i) set Y_ [ expr 10+round(rand()*480) ]
	$node_($i) set Z_ 0.0
}

# Define destino aleatorio e o tempo definido nas variaveis
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at 0 "$node_($i) setdest [ expr 10+round(rand()*480) ] [ expr 10+round(rand()*480) ] $val(speed)"
}

# Configura o CBR sobre o UDP
# Configura os nos
for {set i 0} {$i < [expr $val(nn)/2]} {incr i} {
    set dest [expr [expr $val(nn)/2]+$i]
    set udp [new Agent/UDP]
    $ns attach-agent $node_($i) $udp
    set null [new Agent/Null]
    $ns attach-agent $node_($dest) $null
    $ns connect $udp $null
    set cbr [new Application/Traffic/CBR]
    $cbr attach-agent $udp
    $cbr set packetSize_ $val(pckSize)
    $cbr set interval_ 0.1
    $ns at 1.0 "$cbr start"
    $ns at [expr $val(stop)-5] "$cbr stop"
}

# Define a posicao inicial do no (nam)
for {set i 0} {$i < $val(nn) } { incr i } {
    # 30 define o tamanho do no (nam)
    $ns initial_node_pos $node_($i) 30
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
#Gera o arquivo com o PDR gerado
    exec awk -f Packet_Delivery_Ratio.awk testDSR.tr > outputDSR_1_16.tr &
}

$ns run
