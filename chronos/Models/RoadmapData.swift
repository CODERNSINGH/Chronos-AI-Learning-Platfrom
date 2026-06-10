import Foundation
import SwiftUI

// MARK: - Roadmap Static Definition
// Layout (top → bottom on screen):
//   1.  Advanced Algorithms
//   2.  Dynamic Programming   + Graph Algorithms + Advanced Data Structures
//   3.  DP / Graph / ADS subtopics
//   4.  Sorting & Searching
//   5.  Arrays & Strings
//   6.  Foundation (Big-O, Arrays Basics, Recursion Basics)

struct RoadmapDefinition {
    let id: String
    let name: String
    let category: String
    let difficulty: String       // easy | medium | hard
    let shortDescription: String
    let learnBullets: [String]
    let conceptSummary: String
    let codeExample: CodeExample
    let parents: [String]        // ids of parent nodes; empty = root
    let isRoot: Bool
    let isFoundation: Bool

    struct CodeExample {
        let language: String
        let code: String
        let caption: String
    }
}

enum RoadmapData {
    // MARK: - Visual Layout (rows, top→bottom)
    // Row 0 : Advanced Algorithms (root) + Dynamic Programming
    // Row 1 : DP children / Graph Algorithms / Advanced Data Structures / Sorting & Searching
    // Row 2 : DP leaf / Graph children / ADS children / Sorting children / Arrays & Strings
    // Row 3 : Foundation

    static let allTopics: [RoadmapDefinition] = [
        // ───────── ROW 0 (top): Root & DP ─────────
        RoadmapDefinition(
            id: "advanced_algorithms",
            name: "Advanced Algorithms",
            category: "Root",
            difficulty: "hard",
            shortDescription: "The summit of competitive programming — meta-strategies, problem reduction, and a deep toolkit.",
            learnBullets: [
                "Recognise problem families and reduce them to known paradigms",
                "Combine multiple data structures in a single solution",
                "Reason about amortised complexity",
                "Spot optimisation opportunities during contests"
            ],
            conceptSummary: """
Advanced algorithms combine multiple paradigms — DP, graphs, segment trees, binary search — to solve problems that no single technique can handle alone. The hallmark of expertise is recognising the *family* a problem belongs to and choosing an elegant reduction. Practice by solving mixed-tag problems on Codeforces, LeetCode, and CSES, and by reading editorials to expand your toolkit.
""",
            codeExample: .init(language: "swift", code: """
func twoSumSorted(_ nums: [Int], _ target: Int) -> [Int] {
    var lo = 0, hi = nums.count - 1
    while lo < hi {
        let sum = nums[lo] + nums[hi]
        if sum == target { return [lo, hi] }
        if sum < target  { lo += 1 } else { hi -= 1 }
    }
    return []
}
""", caption: "A two-pointer sweep on a sorted array — a fundamental building block."),
            parents: [],
            isRoot: true,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "dp",
            name: "Dynamic Programming",
            category: "Paradigm",
            difficulty: "hard",
            shortDescription: "Solve complex problems by caching sub-problem results.",
            learnBullets: [
                "Top-down memoisation vs bottom-up tabulation",
                "1-D, 2-D and bitmask DP",
                "State design and transitions",
                "Space optimisation tricks"
            ],
            conceptSummary: """
Dynamic Programming is the art of caching sub-problem answers. A DP solution defines a state that fully captures "where you are", writes a transition to the next state, and chooses a traversal order so that every sub-problem is computed before it is needed. Master it by practising knapsack, longest-common-subsequence and bitmask problems.
""",
            codeExample: .init(language: "swift", code: """
func knapsack(_ weights: [Int], _ values: [Int], _ W: Int) -> Int {
    var dp = Array(repeating: 0, count: W + 1)
    for i in 0..<weights.count {
        for w in stride(from: W, through: weights[i], by: -1) {
            dp[w] = max(dp[w], dp[w - weights[i]] + values[i])
        }
    }
    return dp[W]
}
""", caption: "Classic 0/1 Knapsack — O(n·W) bottom-up DP."),
            parents: ["advanced_algorithms"],
            isRoot: false,
            isFoundation: false
        ),

        // ───────── ROW 1: DP children / Graph / ADS / Sorting ─────────
        RoadmapDefinition(
            id: "dp_knapsack",
            name: "Knapsack Problems",
            category: "Dynamic Programming",
            difficulty: "hard",
            shortDescription: "0/1, unbounded, bounded knapsack variants and subset-sum reductions.",
            learnBullets: [
                "0/1 knapsack with a 1-D rolling array",
                "Unbounded knapsack",
                "Subset sum and partition problems",
                "Bounding the DP state"
            ],
            conceptSummary: """
The knapsack family asks: given items with weights and values, what is the most valuable subset that fits a capacity? The 0/1 variant iterates weights in *reverse* to avoid reusing an item; the unbounded variant iterates forward. Many problems (partition, target-sum, coin-change) reduce to knapsack with a clever transformation.
""",
            codeExample: .init(language: "swift", code: """
func canPartition(_ nums: [Int], _ target: Int) -> Bool {
    var dp = Set([0])
    for n in nums {
        dp = dp.union(dp.map { $0 + n })
    }
    return dp.contains(target)
}
""", caption: "Subset-sum check — does any subset sum to target?"),
            parents: ["dp"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "dp_lcs_lis",
            name: "LCS / LIS",
            category: "Dynamic Programming",
            difficulty: "medium",
            shortDescription: "Longest Common Subsequence and Longest Increasing Subsequence.",
            learnBullets: [
                "2-D DP for LCS",
                "Patience-sorting O(n log n) for LIS",
                "Variants: longest common substring, k-increasing"
            ],
            conceptSummary: """
LCS compares two sequences with a 2-D DP table where dp[i][j] is the LCS length of the first i and first j characters. LIS can be solved in O(n log n) by maintaining a tail array: binary-search the leftmost tail ≥ x and replace it. Both are essential in interview prep.
""",
            codeExample: .init(language: "swift", code: """
func lengthOfLIS(_ a: [Int]) -> Int {
    var tails: [Int] = []
    for x in a {
        var lo = 0, hi = tails.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if tails[mid] < x { lo = mid + 1 } else { hi = mid }
        }
        if lo == tails.count { tails.append(x) } else { tails[lo] = x }
    }
    return tails.count
}
""", caption: "LIS in O(n log n) with patience sorting."),
            parents: ["dp"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "dp_bitmask",
            name: "Bitmask DP",
            category: "Dynamic Programming",
            difficulty: "hard",
            shortDescription: "DP over subsets represented as bit masks for n ≤ 20.",
            learnBullets: [
                "Iterating subsets: for s in 0..<1<<n",
                "Iterating sub-masks of a mask",
                "Travelling salesman problem",
                "Assignment-style DP"
            ],
            conceptSummary: """
When n is small (≤ 20), the state space of size 2ⁿ becomes feasible. A bitmask DP stores a result per subset and uses bitwise operations to enumerate transitions. Classic examples include the Travelling Salesman and the assignment problem.
""",
            codeExample: .init(language: "swift", code: """
for mask in 0..<(1 << n) {
    var sub = mask
    repeat {
        // use sub
        sub = (sub - 1) & mask
    } while sub != mask
}
""", caption: "Iterating over all sub-masks of a mask in O(3ⁿ) total."),
            parents: ["dp"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "dp_tree",
            name: "Tree DP",
            category: "Dynamic Programming",
            difficulty: "hard",
            shortDescription: "DP on tree structures — reroot, subtree DP, dp-on-dominator-tree.",
            learnBullets: [
                "Post-order DFS to compute subtree answers",
                "Reroot DP using a second DFS",
                "DP on DAGs rooted at leaves"
            ],
            conceptSummary: """
Tree DP runs a DFS to compute an answer per subtree, then often performs a second "reroot" pass to compute the answer for every node as the root. This unlocks problems like "sum of distances to all other nodes" in O(n).
""",
            codeExample: .init(language: "swift", code: """
func subtreeSize(_ g: [[Int]], _ u: Int, _ p: Int) -> Int {
    var size = 1
    for v in g[u] where v != p {
        size += subtreeSize(g, v, u)
    }
    return size
}
""", caption: "Subtree size in a single DFS."),
            parents: ["dp"],
            isRoot: false,
            isFoundation: false
        ),

        // Graph
        RoadmapDefinition(
            id: "graph",
            name: "Graph Algorithms",
            category: "Paradigm",
            difficulty: "hard",
            shortDescription: "Traverse, find shortest paths, and analyse connectivity in graphs.",
            learnBullets: [
                "BFS and DFS traversals",
                "Shortest paths (Dijkstra, Bellman-Ford, Floyd–Warshall)",
                "Topological sort and SCCs",
                "Minimum spanning trees"
            ],
            conceptSummary: """
Graphs model relationships. Pick the right traversal (BFS for unweighted shortest paths, DFS for connectivity), the right shortest-path algorithm (Dijkstra for non-negative weights, Bellman-Ford for negative edges, Floyd–Warshall for all-pairs), and the right structural decomposition (topological sort for DAGs, SCCs for condensation).
""",
            codeExample: .init(language: "swift", code: """
func bfs(_ g: [[Int]], _ src: Int) -> [Int] {
    var dist = Array(repeating: -1, count: g.count)
    dist[src] = 0
    var q = [src]
    while !q.isEmpty {
        let u = q.removeFirst()
        for v in g[u] where dist[v] == -1 {
            dist[v] = dist[u] + 1
            q.append(v)
        }
    }
    return dist
}
""", caption: "BFS shortest path on an unweighted graph."),
            parents: ["advanced_algorithms"],
            isRoot: false,
            isFoundation: false
        ),

        // ADS
        RoadmapDefinition(
            id: "ads",
            name: "Advanced Data Structures",
            category: "Paradigm",
            difficulty: "hard",
            shortDescription: "Specialised structures for range queries, union-find and string lookups.",
            learnBullets: [
                "Segment / Fenwick trees for range queries",
                "DSU for connectivity",
                "Trie for prefix operations",
                "Sparse Table for idempotent RMQ"
            ],
            conceptSummary: """
When the naive data structure is too slow, reach for an advanced one. Segment trees support any associative operation in O(log n). Fenwick trees are simpler but limited to invertible operations. DSU merges sets in near-O(1). Trie stores strings. Sparse table answers idempotent RMQ in O(1).
""",
            codeExample: .init(language: "swift", code: """
struct Fenwick {
    var bit: [Int]
    init(_ n: Int) { bit = Array(repeating: 0, count: n + 1) }
    mutating func add(_ i: Int, _ v: Int) {
        var i = i
        while i < bit.count { bit[i] += v; i += i & -i }
    }
    func sum(_ i: Int) -> Int {
        var i = i, s = 0
        while i > 0 { s += bit[i]; i -= i & -i }
        return s
    }
}
""", caption: "Fenwick tree point-update + prefix-sum."),
            parents: ["advanced_algorithms"],
            isRoot: false,
            isFoundation: false
        ),

        // Sorting & Searching
        RoadmapDefinition(
            id: "sorting",
            name: "Sorting & Searching",
            category: "Paradigm",
            difficulty: "easy",
            shortDescription: "Binary search, merge sort, quick sort and beyond.",
            learnBullets: [
                "Binary search on the answer",
                "Merge sort and counting inversions",
                "Quick sort and partition schemes",
                "Stability, in-place vs extra memory"
            ],
            conceptSummary: """
Binary search is the workhorse of "log n" decisions — it works on any monotonic predicate. Merge sort guarantees O(n log n) and can be modified to count inversions or solve related problems. Quick sort is faster in practice but has worst-case O(n²) without a randomised pivot.
""",
            codeExample: .init(language: "swift", code: """
func lowerBound(_ a: [Int], _ x: Int) -> Int {
    var lo = 0, hi = a.count
    while lo < hi {
        let mid = (lo + hi) / 2
        if a[mid] < x { lo = mid + 1 } else { hi = mid }
    }
    return lo
}
""", caption: "Standard lower-bound binary search."),
            parents: ["advanced_algorithms"],
            isRoot: false,
            isFoundation: false
        ),

        // ───────── ROW 2 ─────────
        RoadmapDefinition(
            id: "graph_dijkstra",
            name: "Dijkstra's Algorithm",
            category: "Graph Algorithms",
            difficulty: "medium",
            shortDescription: "Single-source shortest paths on non-negative weight graphs.",
            learnBullets: [
                "Greedy + priority queue",
                "Why non-negative weights matter",
                "Variants with early exit"
            ],
            conceptSummary: """
Dijkstra repeatedly extracts the unvisited vertex with the smallest tentative distance from a min-heap and relaxes its outgoing edges. It runs in O((n + m) log n) and is the canonical answer for "shortest path on a non-negative graph".
""",
            codeExample: .init(language: "swift", code: """
func dijkstra(_ g: [[(Int, Int)]], _ src: Int) -> [Int] {
    var dist = Array(repeating: Int.max, count: g.count)
    dist[src] = 0
    var pq = [(0, src)]
    while let (d, u) = pq.first {
        pq.removeFirst()
        if d > dist[u] { continue }
        for (v, w) in g[u] {
            if dist[v] > d + w {
                dist[v] = d + w
                pq.append((dist[v], v))
            }
        }
    }
    return dist
}
""", caption: "Dijkstra with a heap."),
            parents: ["graph"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "graph_bellman",
            name: "Bellman-Ford",
            category: "Graph Algorithms",
            difficulty: "medium",
            shortDescription: "Handles negative edge weights and detects negative cycles.",
            learnBullets: [
                "Relax every edge n−1 times",
                "Negative-cycle detection on the nth pass",
                "Useful in currency arbitrage problems"
            ],
            conceptSummary: """
Bellman-Ford relaxes every edge up to n−1 times. After n−1 passes the distances are final unless a negative cycle exists, which the nth pass detects. It is slower than Dijkstra but tolerates negative weights.
""",
            codeExample: .init(language: "swift", code: """
func bellmanFord(_ edges: [(Int, Int, Int)], _ n: Int, _ src: Int) -> [Int] {
    var d = Array(repeating: Int.max, count: n)
    d[src] = 0
    for _ in 0..<n - 1 {
        for (u, v, w) in edges where d[u] != .max {
            d[v] = min(d[v], d[u] + w)
        }
    }
    return d
}
""", caption: "Bellman-Ford shortest paths."),
            parents: ["graph"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "graph_fw",
            name: "Floyd-Warshall",
            category: "Graph Algorithms",
            difficulty: "medium",
            shortDescription: "All-pairs shortest paths in O(n³).",
            learnBullets: [
                "Triple nested loop over k, i, j",
                "Transitive closure of a relation",
                "Detecting negative cycles via the diagonal"
            ],
            conceptSummary: """
Floyd-Warshall computes shortest paths between every pair of vertices in O(n³). It is the simplest all-pairs algorithm and also computes transitive closure and helps detect negative cycles.
""",
            codeExample: .init(language: "swift", code: """
for k in 0..<n { for i in 0..<n { for j in 0..<n {
    d[i][j] = min(d[i][j], d[i][k] + d[k][j])
}}}
""", caption: "Floyd-Warshall in 7 lines."),
            parents: ["graph"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "graph_topo",
            name: "Topological Sort",
            category: "Graph Algorithms",
            difficulty: "medium",
            shortDescription: "Linear ordering of a DAG respecting all edges.",
            learnBullets: [
                "Kahn's BFS-based algorithm",
                "DFS-based variant",
                "Detecting cycles"
            ],
            conceptSummary: """
A topological order of a DAG is an ordering such that every edge u→v has u before v. Kahn's algorithm repeatedly removes in-degree-zero vertices; a DFS variant pushes a vertex onto the result list after exploring all its descendants.
""",
            codeExample: .init(language: "swift", code: """
func topoSort(_ g: [[Int]], _ indeg: [Int]) -> [Int]? {
    var d = indeg, q = d.enumerated().filter { $0.element == 0 }.map { $0.offset }
    var order: [Int] = []
    while let u = q.first {
        q.removeFirst(); order.append(u)
        for v in g[u] { d[v] -= 1; if d[v] == 0 { q.append(v) } }
    }
    return order.count == g.count ? order : nil
}
""", caption: "Kahn's topological sort."),
            parents: ["graph"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "graph_tarjan",
            name: "Tarjan's SCC",
            category: "Graph Algorithms",
            difficulty: "hard",
            shortDescription: "Find strongly connected components in linear time.",
            learnBullets: [
                "Low-link values in DFS",
                "Stack-based component extraction",
                "Condensation graph of SCCs"
            ],
            conceptSummary: """
Tarjan's algorithm runs a DFS, tracking discovery time and a low-link value. When a node's low-link equals its discovery time, a strongly connected component is complete and is popped from an explicit stack. Runs in O(n + m).
""",
            codeExample: .init(language: "swift", code: """
func tarjan(_ g: [[Int]]) -> [[Int]] {
    var index = 0, stack: [Int] = [], onStack: [Bool] = [], idx: [Int] = [], low: [Int] = [], sccs: [[Int]] = []
    func strongconnect(_ v: Int) {
        idx[v] = index; low[v] = index; index += 1
        stack.append(v); onStack[v] = true
        for w in g[v] {
            if idx[w] == -1 { strongconnect(w); low[v] = min(low[v], low[w]) }
            else if onStack[w] { low[v] = min(low[v], idx[w]) }
        }
        if low[v] == idx[v] {
            var comp: [Int] = []
            while let w = stack.popLast() { onStack[w] = false; comp.append(w); if w == v { break } }
            sccs.append(comp)
        }
    }
    return sccs
}
""", caption: "Tarjan's SCC core — low-link DFS."),
            parents: ["graph"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "graph_mst",
            name: "MST (Kruskal, Prim)",
            category: "Graph Algorithms",
            difficulty: "medium",
            shortDescription: "Minimum spanning trees — cheapest way to connect all nodes.",
            learnBullets: [
                "Kruskal with DSU",
                "Prim with a priority queue",
                "Cut property & cycle property"
            ],
            conceptSummary: """
A minimum spanning tree connects all vertices with minimum total edge weight. Kruskal sorts edges and adds them greedily if they connect two different components (DSU). Prim grows a single component by repeatedly picking the cheapest edge that leaves it.
""",
            codeExample: .init(language: "swift", code: """
func kruskal(_ edges: [(Int, Int, Int)], _ n: Int) -> Int {
    var dsu = DSU(n), cost = 0
    for (u, v, w) in edges.sorted(by: { $0.2 < $1.2 }) {
        if dsu.find(u) != dsu.find(v) { dsu.union(u, v); cost += w }
    }
    return cost
}
""", caption: "Kruskal with DSU."),
            parents: ["graph"],
            isRoot: false,
            isFoundation: false
        ),

        // Advanced Data Structures children
        RoadmapDefinition(
            id: "ads_seg",
            name: "Segment Tree",
            category: "Advanced Data Structures",
            difficulty: "hard",
            shortDescription: "Range queries and point updates in O(log n).",
            learnBullets: [
                "Iterative segment tree (2n size)",
                "Lazy propagation for range updates",
                "Segment tree beats for range min/max updates"
            ],
            conceptSummary: """
A segment tree stores an aggregated value for every interval in a binary decomposition. Point updates and range queries both run in O(log n). With lazy propagation, range updates can also be O(log n) per operation.
""",
            codeExample: .init(language: "swift", code: """
struct SegTree {
    var n: Int; var t: [Int]
    init(_ a: [Int]) {
        n = a.count; t = Array(repeating: 0, count: 2 * n)
        for i in 0..<n { t[n + i] = a[i] }
        for i in stride(from: n - 1, through: 1, by: -1) { t[i] = t[2*i] + t[2*i+1] }
    }
    mutating func update(_ p: Int, _ v: Int) {
        var i = p + n; t[i] = v
        while i > 1 { i /= 2; t[i] = t[2*i] + t[2*i+1] }
    }
    func query(_ l: Int, _ r: Int) -> Int {
        var l = l + n, r = r + n, s = 0
        while l < r { if l & 1 == 1 { s += t[l]; l += 1 }; l /= 2
                      if r & 1 == 1 { r -= 1; s += t[r] }; r /= 2 }
        return s
    }
}
""", caption: "Iterative segment tree range sum."),
            parents: ["ads"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "ads_fenwick",
            name: "Fenwick Tree (BIT)",
            category: "Advanced Data Structures",
            difficulty: "medium",
            shortDescription: "A compact binary-indexed tree for prefix sums.",
            learnBullets: [
                "add(i, v) and sum(i) in O(log n)",
                "Range-update / point-query variant",
                "2-D BIT for sub-matrix sums"
            ],
            conceptSummary: """
A Fenwick tree stores partial sums indexed by the lowest set bit of each index. It is shorter to code than a segment tree but only supports invertible (or specifically arranged) operations.
""",
            codeExample: .init(language: "swift", code: """
struct Fenwick {
    var bit: [Int]; init(_ n: Int) { bit = Array(repeating: 0, count: n + 1) }
    mutating func add(_ i: Int, _ v: Int) {
        var i = i; while i < bit.count { bit[i] += v; i += i & -i }
    }
    func sum(_ i: Int) -> Int {
        var i = i, s = 0; while i > 0 { s += bit[i]; i -= i & -i }
        return s
    }
}
""", caption: "Fenwick add + sum."),
            parents: ["ads"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "ads_trie",
            name: "Trie",
            category: "Advanced Data Structures",
            difficulty: "medium",
            shortDescription: "Prefix tree for fast string operations.",
            learnBullets: [
                "Insert / search / startsWith in O(L)",
                "Compressed / radix tries",
                "Tries with bit masks for XOR problems"
            ],
            conceptSummary: """
A trie stores strings character-by-character, sharing common prefixes. Lookups run in time proportional to the key length. Bitwise tries are the foundation of "maximum XOR of any pair" type problems.
""",
            codeExample: .init(language: "swift", code: """
class Trie {
    var children: [Trie?] = Array(repeating: nil, count: 26)
    var end = false
    func insert(_ w: String) {
        var node = self
        for ch in w {
            let i = Int(ch.asciiValue! - 97)
            if node.children[i] == nil { node.children[i] = Trie() }
            node = node.children[i]!
        }
        node.end = true
    }
}
""", caption: "Insert and search in a 26-letter trie."),
            parents: ["ads"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "ads_dsu",
            name: "Disjoint Set Union (DSU)",
            category: "Advanced Data Structures",
            difficulty: "easy",
            shortDescription: "Near-constant-time union-find with path compression and union by rank.",
            learnBullets: [
                "find(x) with path compression",
                "union(x, y) with union by rank/size",
                "Applications in Kruskal and connectivity"
            ],
            conceptSummary: """
DSU maintains a partition of elements into disjoint sets. find returns the canonical representative; union merges two sets. With path compression and union by rank every operation is amortised α(n) — essentially constant.
""",
            codeExample: .init(language: "swift", code: """
struct DSU {
    var p: [Int]; var r: [Int]
    init(_ n: Int) { p = Array(0..<n); r = Array(repeating: 0, count: n) }
    mutating func find(_ x: Int) -> Int {
        if p[x] == x { return x }
        p[x] = find(p[x]); return p[x]
    }
    mutating func union(_ a: Int, _ b: Int) {
        let ra = find(a), rb = find(b)
        if ra == rb { return }
        if r[ra] < r[rb] { p[ra] = rb }
        else if r[ra] > r[rb] { p[rb] = ra }
        else { p[rb] = ra; r[ra] += 1 }
    }
}
""", caption: "DSU with path compression and union by rank."),
            parents: ["ads"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "ads_sparse",
            name: "Sparse Table",
            category: "Advanced Data Structures",
            difficulty: "medium",
            shortDescription: "Idempotent range queries in O(1) after O(n log n) build.",
            learnBullets: [
                "st[k][i] = min(arr[i..<i+2^k])",
                "Query in O(1) for min/max/gcd",
                "Disjoint pair trick to avoid overlap"
            ],
            conceptSummary: """
A sparse table precomputes the answer for every interval of length 2ᵏ. Idempotent queries (min, max, gcd) answer in O(1) by combining two overlapping intervals. Non-idempotent queries (sum) need a different structure.
""",
            codeExample: .init(language: "swift", code: """
let n = a.count
var k = 0
while (1 << k) <= n { k += 1 }
var st = Array(repeating: Array(repeating: 0, count: n), count: k)
st[0] = a
for i in 1..<k {
    for j in 0...(n - (1 << i)) {
        st[i][j] = min(st[i-1][j], st[i-1][j + (1 << (i-1))])
    }
}
""", caption: "RMQ with sparse table."),
            parents: ["ads"],
            isRoot: false,
            isFoundation: false
        ),

        // Sorting & Searching children
        RoadmapDefinition(
            id: "sorting_binary",
            name: "Binary Search (Advanced)",
            category: "Sorting & Searching",
            difficulty: "medium",
            shortDescription: "Binary search on answers, on floats, and on monotonic predicates.",
            learnBullets: [
                "Standard lower/upper bound",
                "Searching on the answer (parametric search)",
                "Float / double binary search"
            ],
            conceptSummary: """
"Binary search on the answer" turns an optimisation into a decision problem: ask "is X feasible?" and binary-search the largest X for which it is. This unlocks problems like "minimum maximum subarray sum" and many scheduling tasks.
""",
            codeExample: .init(language: "swift", code: """
func bsearch(_ lo: Double, _ hi: Double, _ ok: (Double) -> Bool) -> Double {
    var l = lo, r = hi
    for _ in 0..<80 {
        let m = (l + r) / 2
        if ok(m) { r = m } else { l = m }
    }
    return r
}
""", caption: "Binary search on a boolean predicate."),
            parents: ["sorting"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "sorting_merge",
            name: "Merge Sort",
            category: "Sorting & Searching",
            difficulty: "medium",
            shortDescription: "Stable O(n log n) divide-and-conquer sort.",
            learnBullets: [
                "Top-down recursive merge sort",
                "Bottom-up iterative variant",
                "Counting inversions during merge"
            ],
            conceptSummary: """
Merge sort recursively halves the array, sorts each half, and merges the two sorted halves in linear time. The merge step can be extended to count inversions (number of pairs i<j with a[i]>a[j]) in O(n log n).
""",
            codeExample: .init(language: "swift", code: """
func countInv(_ a: [Int]) -> Int {
    if a.count <= 1 { return 0 }
    let m = a.count / 2
    let left = Array(a[0..<m]), right = Array(a[m..<a.count])
    var inv = countInv(left) + countInv(right)
    var i = 0, j = 0
    var merged: [Int] = []
    while i < left.count && j < right.count {
        if left[i] <= right[j] { merged.append(left[i]); i += 1 }
        else { merged.append(right[j]); inv += left.count - i; j += 1 }
    }
    return inv
}
""", caption: "Counting inversions with merge sort."),
            parents: ["sorting"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "sorting_quick",
            name: "Quick Sort",
            category: "Sorting & Searching",
            difficulty: "medium",
            shortDescription: "Cache-friendly O(n log n) average-case sort with a randomised pivot.",
            learnBullets: [
                "Lomuto vs Hoare partition",
                "Randomised pivot to avoid worst case",
                "Tail-call elimination for stack depth"
            ],
            conceptSummary: """
Quick sort picks a pivot, partitions the array into elements ≤ and > pivot, then recurses on the two sides. With a randomised pivot the expected time is O(n log n); pathological inputs (already sorted, all-equal) are handled by 3-way partitioning.
""",
            codeExample: .init(language: "swift", code: """
func qsort(_ a: inout [Int], _ lo: Int, _ hi: Int) {
    if lo >= hi { return }
    let p = a[hi]
    var i = lo
    for j in lo..<hi { if a[j] <= p { a.swapAt(i, j); i += 1 } }
    a.swapAt(i, hi)
    qsort(&a, lo, i - 1); qsort(&a, i + 1, hi)
}
""", caption: "In-place quick sort with Lomuto partition."),
            parents: ["sorting"],
            isRoot: false,
            isFoundation: false
        ),

        // Arrays & Strings
        RoadmapDefinition(
            id: "arrays_strings",
            name: "Arrays & Strings",
            category: "Paradigm",
            difficulty: "easy",
            shortDescription: "Two pointers, sliding windows, prefix sums and string tricks.",
            learnBullets: [
                "Two-pointer and sliding window patterns",
                "Prefix sums and range queries",
                "Kadane's algorithm for max subarray",
                "String hashing and rolling hashes"
            ],
            conceptSummary: """
The everyday toolkit. Two pointers collapse O(n²) brute forces into O(n) on sorted or paired data. Sliding windows maintain a *valid* sub-array as the window expands and contracts. Prefix sums answer range-sum queries in O(1) after an O(n) build.
""",
            codeExample: .init(language: "swift", code: """
func maxSumK(_ a: [Int], _ k: Int) -> Int {
    var sum = a[0..<k].reduce(0, +), best = sum
    for i in k..<a.count {
        sum += a[i] - a[i - k]
        best = max(best, sum)
    }
    return best
}
""", caption: "Classic sliding window for max sum of k consecutive elements."),
            parents: ["advanced_algorithms"],
            isRoot: false,
            isFoundation: false
        ),

        // Arrays & Strings children
        RoadmapDefinition(
            id: "arrays_two_pointers",
            name: "Two Pointers",
            category: "Arrays & Strings",
            difficulty: "easy",
            shortDescription: "Walk two indices through an array to solve in linear time.",
            learnBullets: [
                "Sorted two-sum in O(n)",
                "Fast/slow pointer for cycle detection",
                "Three-pointer Dutch national flag"
            ],
            conceptSummary: """
Two pointers is a technique where two indices walk through the array — often from opposite ends or at different speeds — to solve a problem in O(n) that a naive O(n²) approach would take.
""",
            codeExample: .init(language: "swift", code: """
func twoSum(_ a: [Int], _ target: Int) -> [Int] {
    var lo = 0, hi = a.count - 1
    while lo < hi {
        let s = a[lo] + a[hi]
        if s == target { return [lo, hi] }
        s < target ? (lo += 1) : (hi -= 1)
    }
    return []
}
""", caption: "Two-sum on a sorted array."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "arrays_sliding",
            name: "Sliding Window",
            category: "Arrays & Strings",
            difficulty: "medium",
            shortDescription: "Maintain a valid sub-array as the window expands and contracts.",
            learnBullets: [
                "Fixed-size window for max/min sum",
                "Variable-size window with two pointers",
                "Counting distinct elements in a window"
            ],
            conceptSummary: """
Sliding window maintains a contiguous window over the input and adjusts the left and right edges to keep the window *valid* for the current problem. It is the standard answer to "longest/shortest subarray with property X".
""",
            codeExample: .init(language: "swift", code: """
func lengthOfLongestKDistinct(_ s: String, _ k: Int) -> Int {
    var counts: [Character: Int] = [:]
    var lo = 0, best = 0
    let chars = Array(s)
    for hi in 0..<chars.count {
        counts[chars[hi], default: 0] += 1
        while counts.count > k {
            counts[chars[lo]]! -= 1
            if counts[chars[lo]] == 0 { counts.removeValue(forKey: chars[lo]) }
            lo += 1
        }
        best = max(best, hi - lo + 1)
    }
    return best
}
""", caption: "Longest substring with at most k distinct characters."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "arrays_prefix",
            name: "Prefix Sum",
            category: "Arrays & Strings",
            difficulty: "easy",
            shortDescription: "Pre-compute cumulative sums to answer range queries in O(1).",
            learnBullets: [
                "1-D prefix sums",
                "2-D prefix sums for sub-matrices",
                "Difference arrays for range updates"
            ],
            conceptSummary: """
A prefix-sum array p[i] = a[0] + ... + a[i-1] turns the range-sum query sum(l, r) into p[r+1] − p[l] in O(1). In 2-D, prefix sums answer sub-matrix sum queries in O(1) after an O(n²) build.
""",
            codeExample: .init(language: "swift", code: """
let p = Array(repeating: 0, count: a.count + 1)
for i in 0..<a.count { p[i + 1] = p[i] + a[i] }
func rangeSum(_ l: Int, _ r: Int) -> Int { p[r + 1] - p[l] }
""", caption: "Range sum with prefix sums."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "arrays_kadane",
            name: "Kadane's Algorithm",
            category: "Arrays & Strings",
            difficulty: "medium",
            shortDescription: "Maximum subarray sum in linear time.",
            learnBullets: [
                "Local maximum at each position",
                "Reset on negative running sum",
                "Extensions to circular arrays"
            ],
            conceptSummary: """
Kadane's algorithm tracks the best subarray that *ends* at each position: either extend the previous best or start fresh. The global max is the largest of these. Runs in O(n) time and O(1) space.
""",
            codeExample: .init(language: "swift", code: """
func maxSubArray(_ a: [Int]) -> Int {
    var best = a[0], cur = a[0]
    for i in 1..<a.count {
        cur = max(a[i], cur + a[i])
        best = max(best, cur)
    }
    return best
}
""", caption: "Kadane's algorithm."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: false
        ),

        RoadmapDefinition(
            id: "arrays_hashing",
            name: "String Hashing",
            category: "Arrays & Strings",
            difficulty: "hard",
            shortDescription: "Rolling hashes for O(1) substring comparisons and palindromic trees.",
            learnBullets: [
                "Polynomial rolling hash",
                "Collision probability and double hashing",
                "Z-algorithm and KMP for exact matching"
            ],
            conceptSummary: """
A rolling hash represents a string as a number in a large base. By precomputing prefix hashes you can compare any two substrings in O(1). With double hashing the collision probability is negligible.
""",
            codeExample: .init(language: "swift", code: """
let base = 91138233, mod = 1_000_000_007
var h = Array(repeating: 0, count: s.count + 1)
var p = Array(repeating: 1, count: s.count + 1)
for i in 0..<s.count {
    h[i + 1] = (h[i] * base + Int(s[i].asciiValue!)) % mod
    p[i + 1] = (p[i] * base) % mod
}
func hashOf(_ l: Int, _ r: Int) -> Int {  // [l, r)
    (h[r] - h[l] * p[r - l] % mod + mod) % mod
}
""", caption: "Polynomial rolling hash for substrings."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: false
        ),

        // ───────── ROW 3: Foundation ─────────
        RoadmapDefinition(
            id: "found_bigo",
            name: "Big-O Notation",
            category: "Foundation",
            difficulty: "easy",
            shortDescription: "Quantify how an algorithm's runtime scales with input size.",
            learnBullets: [
                "O, Ω and Θ notations",
                "Common complexity classes",
                "Amortised and average-case analysis"
            ],
            conceptSummary: """
Big-O notation describes the upper bound of an algorithm's runtime as the input grows. It hides constants and lower-order terms, focusing on the dominant factor. Knowing the complexity of every operation in your toolkit is the first step toward writing efficient code.
""",
            codeExample: .init(language: "swift", code: """
// O(n) — linear search
for x in a { if x == target { return true } }
// O(log n) — binary search on sorted array
var lo = 0, hi = a.count - 1
while lo <= hi {
    let m = (lo + hi) / 2
    if a[m] == target { return true }
    a[m] < target ? (lo = m + 1) : (hi = m - 1)
}
""", caption: "Comparing linear and binary search complexities."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: true
        ),

        RoadmapDefinition(
            id: "found_arrays",
            name: "Arrays Basics",
            category: "Foundation",
            difficulty: "easy",
            shortDescription: "The most fundamental data structure — contiguous, indexed storage.",
            learnBullets: [
                "Indexing, iteration and slicing",
                "Common operations: insert, delete, search",
                "Memory layout and cache-friendliness"
            ],
            conceptSummary: """
An array is a contiguous block of memory storing elements of a fixed size. It supports O(1) random access by index and O(n) insertion/deletion in the middle. Arrays are the building block of nearly every other data structure.
""",
            codeExample: .init(language: "swift", code: """
var nums = [3, 1, 4, 1, 5, 9, 2, 6]
nums.append(7)                  // O(1) amortised
nums.insert(0, at: 0)           // O(n) — shifts
let s = nums.reduce(0, +)       // O(n)
print(nums.sorted())            // O(n log n)
""", caption: "Array basics in Swift."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: true
        ),

        RoadmapDefinition(
            id: "found_recursion",
            name: "Recursion Basics",
            category: "Foundation",
            difficulty: "easy",
            shortDescription: "Functions that call themselves — the gateway to divide-and-conquer and DP.",
            learnBullets: [
                "Base case and recursive case",
                "Call stack and stack overflow",
                "Tail-recursion optimisation"
            ],
            conceptSummary: """
A recursive function solves a problem by calling itself on a smaller sub-problem until a base case is reached. Recursion is the natural form for trees, divide-and-conquer algorithms and DP. Always define a base case — the smallest input for which the answer is trivial.
""",
            codeExample: .init(language: "swift", code: """
func factorial(_ n: Int) -> Int {
    n <= 1 ? 1 : n * factorial(n - 1)
}
func factorialIter(_ n: Int) -> Int {
    var r = 1
    for i in 2...n { r *= i }
    return r
}
""", caption: "Factorial, recursive and iterative."),
            parents: ["arrays_strings"],
            isRoot: false,
            isFoundation: true
        )
    ]

    static func topic(withID id: String) -> RoadmapDefinition? {
        allTopics.first { $0.id == id }
    }

    static func children(of id: String) -> [RoadmapDefinition] {
        allTopics.filter { $0.parents.contains(id) }
    }

    static var rootID: String { "advanced_algorithms" }

    /// Topics ordered for the tree (top → bottom).
    static var layoutOrder: [RoadmapDefinition] {
        let root = allTopics.first { $0.isRoot }!
        let dp = allTopics.first { $0.id == "dp" }!
        let graph = allTopics.first { $0.id == "graph" }!
        let ads = allTopics.first { $0.id == "ads" }!
        let sorting = allTopics.first { $0.id == "sorting" }!
        let arrays = allTopics.first { $0.id == "arrays_strings" }!

        let dpChildren = children(of: "dp").sorted { $0.id < $1.id }
        let graphChildren = children(of: "graph").sorted { $0.id < $1.id }
        let adsChildren = children(of: "ads").sorted { $0.id < $1.id }
        let sortingChildren = children(of: "sorting").sorted { $0.id < $1.id }
        let arraysChildren = children(of: "arrays_strings").sorted { $0.id < $1.id }
        let foundation = allTopics.filter { $0.isFoundation }.sorted { $0.id < $1.id }

        return [
            root, dp,
            // Row 1
            dpChildren[0], dpChildren[1], dpChildren[2], dpChildren[3],
            graph, ads, sorting,
            // Row 2
            dpChildren[0], dpChildren[1], dpChildren[2], dpChildren[3],
            graphChildren[0], graphChildren[1], graphChildren[2], graphChildren[3], graphChildren[4], graphChildren[5],
            adsChildren[0], adsChildren[1], adsChildren[2], adsChildren[3], adsChildren[4],
            sortingChildren[0], sortingChildren[1], sortingChildren[2],
            arrays,
            // Row 3
            dpChildren[0], dpChildren[1], dpChildren[2], dpChildren[3],
            graphChildren[0], graphChildren[1], graphChildren[2], graphChildren[3], graphChildren[4], graphChildren[5],
            adsChildren[0], adsChildren[1], adsChildren[2], adsChildren[3], adsChildren[4],
            sortingChildren[0], sortingChildren[1], sortingChildren[2],
            arraysChildren[0], arraysChildren[1], arraysChildren[2], arraysChildren[3], arraysChildren[4],
            foundation[0], foundation[1], foundation[2]
        ].compactMap { $0 }
    }
}

// MARK: - UI metadata (icons, accents, ordering)

extension RoadmapDefinition {
    /// SF Symbol used as the topic's primary icon in the roadmap tree.
    var topicIcon: String {
        switch id {
        case "advanced_algorithms":    return "crown.fill"
        case "dp":                     return "rectangle.split.3x3.fill"
        case "dp_knapsack":            return "bag.fill"
        case "dp_lcs_lis":             return "ruler.fill"
        case "dp_bitmask":             return "circle.grid.cross.fill"
        case "dp_tree":                return "leaf.arrow.triangle.circlepath"
        case "graph":                  return "point.3.connected.trianglepath.fill"
        case "graph_dijkstra":         return "arrow.triangle.branch"
        case "graph_bellman":          return "arrow.left.and.right.circle.fill"
        case "graph_fw":               return "square.grid.3x3.fill"
        case "graph_topo":             return "arrow.up.and.down.text.horizontal"
        case "graph_tarjan":           return "link.circle.fill"
        case "graph_mst":              return "tree.fill"
        case "ads":                    return "cube.fill"
        case "ads_seg":                return "rectangle.split.2x1.fill"
        case "ads_fenwick":            return "square.stack.3d.up.fill"
        case "ads_trie":               return "f.cursive"
        case "ads_dsu":                return "rectangle.connected.to.line.below"
        case "ads_sparse":             return "tablecells.fill"
        case "sorting":                return "arrow.up.arrow.down.square.fill"
        case "sorting_binary":         return "magnifyingglass.circle.fill"
        case "sorting_merge":          return "arrow.triangle.merge"
        case "sorting_quick":          return "bolt.circle.fill"
        case "arrays_strings":         return "list.bullet.rectangle.portrait.fill"
        case "arrays_two_pointers":    return "arrow.left.and.right.square.fill"
        case "arrays_sliding":         return "rectangle.portrait.and.arrow.right.fill"
        case "arrays_prefix":          return "plus.forwardslash.minus"
        case "arrays_kadane":          return "waveform.path.ecg"
        case "arrays_hashing":         return "number.circle.fill"
        case "found_bigo":             return "function"
        case "found_arrays":           return "square.grid.2x2.fill"
        case "found_recursion":        return "arrow.triangle.2.circlepath"
        default:                       return "book.fill"
        }
    }

    /// Accent colour per category, used to tint icons, rings and progress bars.
    var topicAccent: Color {
        switch category {
        case "Root":                       return Color(red: 0.97, green: 0.55, blue: 0.20)
        case "Paradigm":                   return Color(red: 0.95, green: 0.45, blue: 0.20)
        case "Dynamic Programming":        return Color(red: 0.98, green: 0.68, blue: 0.18)
        case "Graph Algorithms":           return Color(red: 0.32, green: 0.62, blue: 0.95)
        case "Advanced Data Structures":   return Color(red: 0.68, green: 0.42, blue: 0.95)
        case "Sorting & Searching":        return Color(red: 0.18, green: 0.74, blue: 0.55)
        case "Arrays & Strings":           return Color(red: 0.95, green: 0.42, blue: 0.58)
        case "Foundation":                 return Color(red: 0.58, green: 0.60, blue: 0.72)
        default:                           return ChronosTheme.amber
        }
    }

    /// Sort order: bottom-up learning path (Foundation first → Root last).
    var categoryOrder: Int {
        switch category {
        case "Foundation":               return 0
        case "Arrays & Strings":         return 1
        case "Sorting & Searching":      return 2
        case "Graph Algorithms":         return 3
        case "Advanced Data Structures": return 4
        case "Dynamic Programming":      return 5
        case "Paradigm":                 return 6
        case "Root":                     return 7
        default:                         return 99
        }
    }
}
