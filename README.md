# Peer-to-Peer Chord Algorithm

## Implementations of two versions of the Chord Peer-to-Peer algorithm

Chord Ring: a virtual circle formed by all nodes participating in the network
Finger Table: a scalability feature ensuring lookup time of O(log(N))

### Notes about the Chord algorithm:
1. It is a DHT (Distributed Hash Table) implementation
2. For node and item IDs it uses a unique hash (SHA1 in this particular application)
3. Nodes are connected in a "Chord ring" (circle) and linked forming a circle which is spread evenly due to the consistent hashing
4. Nodes communicate through each other using their successor pointers (pointer to succeding node in the ring) in the naive implementation. Lookup time of an item in the ring is O(N)
5. Nodes communicate through "finger tables" in the scalable solution having access only to a limited amount of nodes O(log(N)) and search time complexity is O(log(N)) also
6. When a node leaves the chord ring all the data that it is responsible for is redistributed to the nearest node and successor links are reformed
