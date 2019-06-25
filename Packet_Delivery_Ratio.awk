BEGIN {
    seqno = -1; 
    droppedPackets = 0;
    receivedPackets = 0;
    count = 0;
}

{
    if($4 == "AGT" && $1 == "s" && seqno < $6) {
        seqno = $6;
    } else if(($4 == "AGT") && ($1 == "r")) {
        receivedPackets++;
    } else if ($1 == "D" && $7 == "udp" && $8 > 512){
        droppedPackets++; 
    }
}

END { 
    print "\n";
    print "GeneratedPackets = " seqno+1;
    print "ReceivedPackets = " receivedPackets;
    print "Packet Delivery Ratio = " receivedPackets/(seqno+1)*100
    "%";
}