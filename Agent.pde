class Agent implements Comparable<Agent> {
  float x, y; // Draw coordinates
  int ix, iy; // Maze coordinates (indexes)
  boolean[] genome;
  HashSet<Integer> visited;
  float distance; // Distance to exit
  int illegal; // Number of illegal moves
  boolean reached; // Reached the exit
  int duration; // Number of moves spent reaching exit
  boolean blocked; // Made an illegal move
  int preblocked; // Successful moves pre- illegal move
  int id = (int) random(0, 99999);
  boolean deadend; // Got stuck in a dead-end
  
  Agent() {
    genome = new boolean[NUM_MOVES * 2];
    for (int i = 0; i < NUM_MOVES * 2; i++) {
      genome[i] = agentRand.nextInt() % 2 == 0;
    }
    visited = new HashSet<>();
  }
  
  Agent(boolean[] genome) {
    this.genome = genome;
    visited = new HashSet<>();
  }
  
  int getFitness() {
    if (deadend) return -10000;
    return reached ? 1000000 - duration : preblocked * 10 - illegal + 100 * (int) (dist(0, 0, MAZE_LEN - 1, MAZE_LEN - 1) - distance);
  }
  
  Agent crossover(Agent o, int k) {
    boolean[] childGenome = new boolean[NUM_MOVES * 2];
    for (int i = 0; i < NUM_MOVES; i++) {
      if (i < k) {
        childGenome[2 * i] = genome[2 * i];
        childGenome[2 * i + 1] = genome[2 * i + 1];
      } else {
        childGenome[2 * i] = o.genome[2 * i];
        childGenome[2 * i + 1] = o.genome[2 * i + 1];
      }
    }
    
    return new Agent(childGenome);
  }
  
  void mutate() {
    for (int i = 0; i < NUM_MOVES * 2; i++) {
      if (agentRand.nextFloat() < MUTATION_RATE) {
        genome[i] = !genome[i];
      }
    }
  }
  
  @Override
  public int compareTo(Agent o) {
    return o.getFitness() - getFitness();
  }
}
