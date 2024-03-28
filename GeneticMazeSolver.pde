import java.util.*;

final color BACKGROUND = #757f49;
final color BORDER = #665329;
final color HIGHLIGHT = #c7cbb6;
final color TEXT_COLOR = #2a291e;
final color TEXT_IMP = #906b16;
PFont TITLE_FONT;
PFont SUB_FONT;
PFont TEXT_FONT;

final int MAZE_LEN = 39;
final int NUM_AGENTS = 1024; // Should be divisible by 4 (since agents in top 50% are paired together for reproduction)
final int NUM_MOVES = 1100;
final float MUTATION_RATE = 0.4;

Random mazeRand = new Random(269);
Random agentRand = new Random(123);
boolean[] maze = new boolean[MAZE_LEN * MAZE_LEN];
Agent[] agents = new Agent[NUM_AGENTS];
ArrayList<Integer> explorationRate = new ArrayList<>();
ArrayList<Float> successRate = new ArrayList<>();

int move = 0;
int gen = 1;
boolean updated = true;
boolean fastMode = false;
boolean successful = false;

void initMaze() {
  for (int i = 0; i < MAZE_LEN; i += 2) {
    for (int j = 0; j < MAZE_LEN; j += 2) {
      maze[i + j * MAZE_LEN] = true;
    }
  }
}

void genMaze() {
  initMaze();
  boolean[] visited = new boolean[MAZE_LEN * MAZE_LEN];
  recursiveTraverse(0, 0, visited);
}

void recursiveTraverse(int x, int y, boolean[] visited) {
  ArrayList<Integer> directions = new ArrayList<>(Arrays.asList(0, 1, 2, 3));
  Collections.shuffle(directions, mazeRand);
  visited[x + y * MAZE_LEN] = true;
  for (int i = 0; i < directions.size(); i++) {
    if (directions.get(i) == 0 && y - 2 >= 0 && !visited[x + (y - 2) * MAZE_LEN]) {
      maze[x + (y - 1) * MAZE_LEN] = true;
      recursiveTraverse(x, y - 2, visited);
    } else if (directions.get(i) == 1 && x + 2 < MAZE_LEN && !visited[x + 2 + y * MAZE_LEN]) {
      maze[x + 1 + y * MAZE_LEN] = true;
      recursiveTraverse(x + 2, y, visited);
    } else if (directions.get(i) == 2 && y + 2 < MAZE_LEN && !visited[x + (y + 2) * MAZE_LEN]) {
      maze[x + (y + 1) * MAZE_LEN] = true;
      recursiveTraverse(x, y + 2, visited);
    } else if (directions.get(i) == 3 && x - 2 >= 0 && !visited[x - 2 + y * MAZE_LEN]) {
      maze[x - 1 + y * MAZE_LEN] = true;
      recursiveTraverse(x - 2, y, visited);
    }
  }
}

void drawMaze(int x, int y, int s) {
  int mazeLength = s * MAZE_LEN + 16;
  fill(BORDER);
  noStroke();
  rect(x, y, mazeLength, mazeLength);
  for (int i = 0; i < MAZE_LEN; i++) {
    for (int j = 0; j < MAZE_LEN; j++) {
      fill(maze[i + j * MAZE_LEN] ? #a3977e : BORDER);
      if ((i == 0 && j == 0) || (i == MAZE_LEN - 1 && j == MAZE_LEN - 1)) {
        fill(TEXT_IMP);
      }
      rect(x + s * i + 8, y + s * j + 8, s, s);
    }
  }
}

void initAgents() {
  for (int i = 0; i < NUM_AGENTS; i++) {
    agents[i] = new Agent();
  }
}

void updateAgents(int turn) {
  for (int i = 0; i < NUM_AGENTS; i++) {
    int x = agents[i].ix;
    int y = agents[i].iy;
    boolean[] genome = agents[i].genome;
    if (!agents[i].visited.add(x + y * MAZE_LEN)) {
      agents[i].illegal ++;
      agents[i].blocked = true;
    } else if (!agents[i].blocked) {
      agents[i].preblocked ++;
    }
    if (x == MAZE_LEN - 1 && y == MAZE_LEN - 1) {
      agents[i].reached = true;
      successful = true;
      agents[i].duration = turn;
    }
    if ((y - 1 < 0 || !maze[x + (y - 1) * MAZE_LEN] || agents[i].visited.contains(x + (y - 1) * MAZE_LEN)) &&
    (x + 1 >= MAZE_LEN || !maze[x + 1 + y * MAZE_LEN] || agents[i].visited.contains(x + 1 + y * MAZE_LEN)) &&
    (y + 1 >= MAZE_LEN || !maze[x + (y + 1) * MAZE_LEN] || agents[i].visited.contains(x + (y + 1) * MAZE_LEN)) &&
    (x - 1 < 0 || !maze[x - 1 + y * MAZE_LEN] || agents[i].visited.contains(x - 1 + y * MAZE_LEN)))
    {
      agents[i].deadend = true;
    }
    if (!genome[turn * 2] && !genome[turn * 2 + 1] && y - 1 >= 0 && maze[x + (y - 1) * MAZE_LEN] && !agents[i].visited.contains(x + (y - 1) * MAZE_LEN)) {
      agents[i].iy --;
    } else if (!genome[turn * 2] && genome[turn * 2 + 1] && x + 1 < MAZE_LEN && maze[x + 1 + y * MAZE_LEN] && !agents[i].visited.contains(x + 1 + y * MAZE_LEN)) {
      agents[i].ix ++;
    } else if (genome[turn * 2] && !genome[turn * 2 + 1] && y + 1 < MAZE_LEN && maze[x + (y + 1) * MAZE_LEN] && !agents[i].visited.contains(x + (y + 1) * MAZE_LEN)) {
      agents[i].iy ++;
    } else if (genome[turn * 2] && genome[turn * 2 + 1] && x - 1 >= 0 && maze[x - 1 + y * MAZE_LEN] && !agents[i].visited.contains(x - 1 + y * MAZE_LEN)) {
      agents[i].ix --;
    }
  }
}

void slideAgents() {
  for (int i = 0; i < NUM_AGENTS; i++) {
    agents[i].x -= (agents[i].x - agents[i].ix) / 2.0;
    agents[i].y -= (agents[i].y - agents[i].iy) / 2.0;
  }
}

void drawAgents(int x, int y, int s) {
  fill(255, 0, 0, 50);
  for (int i = 0; i < NUM_AGENTS; i++) {
    if (!agents[i].reached) {
      rect(x + s * agents[i].x + 12, y + s * agents[i].y + 12, s - 8, s - 8);
    }
  }
}

void drawExactAgents(int x, int y, int s) {
  fill(255, 0, 0, 50);
  for (int i = 0; i < NUM_AGENTS; i++) {
    if (!agents[i].reached) {
      rect(x + s * agents[i].ix + 12, y + s * agents[i].iy + 12, s - 8, s - 8);
    }
  }
}

void drawExplorationRate(int x, int y, ArrayList<Integer> rate) {
  stroke(BORDER);
  strokeWeight(8);
  fill(HIGHLIGHT);
  rect(x + 4, y + 4, 1052, 552);
  textFont(SUB_FONT);
  fill(TEXT_COLOR);
  text("Average Distance Explored", x + 530, y + 54);
  textFont(TEXT_FONT);
  text("0", x + 35, y + 530);
  text("500", x + 35, y + 105);
  noFill();
  stroke(TEXT_COLOR);
  strokeWeight(4);
  beginShape(); // Max
  for (int i = 0; i < rate.size(); i++) {
    vertex(x + 70 + (965.0 / (rate.size() - 1)) * i, y + 530 - 425 * (rate.get(i) / 500.0));
  }
  endShape();
}

void drawLegalRate(int x, int y, ArrayList<Float> rate) {
  stroke(BORDER);
  strokeWeight(8);
  fill(HIGHLIGHT);
  rect(x + 4, y + 4, 1052, 552);
  textFont(SUB_FONT);
  fill(TEXT_COLOR);
  text("Average Legal Moves Made", x + 530, y + 54);
  textFont(TEXT_FONT);
  text("0%", x + 38, y + 530);
  text("100%", x + 38, y + 105);
  noFill();
  stroke(TEXT_COLOR);
  strokeWeight(4);
  beginShape(); // Max
  for (int i = 0; i < rate.size(); i++) {
    vertex(x + 70 + (965.0 / (rate.size() - 1)) * i, y + 530 - 425 * (rate.get(i) / 500.0));
  }
  endShape();
}

int calcExploreRate() {
  int sum = 0;
  for (int i = 0; i < NUM_AGENTS; i++) {
    sum += NUM_MOVES - agents[i].illegal;
  }
  return sum / NUM_AGENTS;
}

float calcLegalRate() {
  int sum = 0;
  for (int i = 0; i < NUM_AGENTS; i++) {
    sum += NUM_MOVES - agents[i].illegal;
  }
  return sum / NUM_AGENTS;
}

void setup() {
  fullScreen();
  frameRate(120);
  TITLE_FONT = loadFont("JetBrainsMonoSlashed-Regular-96.vlw");
  SUB_FONT = loadFont("JetBrainsMonoSlashed-Regular-48.vlw");
  TEXT_FONT = loadFont("JetBrainsMonoSlashed-Regular-24.vlw");
  textAlign(CENTER, CENTER);
  
  // Generate the maze
  genMaze();
  
  // Initialize the population
  initAgents();
  
  // Initial draw
  background(BACKGROUND);
  drawMaze(68, 68, 33);
  textFont(TITLE_FONT);
  fill(TEXT_COLOR);
  text("Generation " + gen, 1967, 100);
}

void draw() {
  if (!updated) {
    if (fastMode && move < NUM_MOVES) {
      for (; move < NUM_MOVES; move++) {
        updateAgents(move);
      }
    } else if (move < NUM_MOVES/* && frameCount % 2 == 0*/) { // Simulate agents
      updateAgents(move);
      move ++;
    } else if (move >= NUM_MOVES) { // Simulation complete
      // Perform selection
      for (int i = 0; i < NUM_AGENTS; i++) {
        agents[i].distance = dist(agents[i].ix, agents[i].iy, MAZE_LEN - 1, MAZE_LEN - 1);
      }
      Arrays.sort(agents);
      Agent[] parents = Arrays.copyOfRange(agents, 0, NUM_AGENTS / 2);
      
      // Collect some stats
      explorationRate.add(calcExploreRate());
      successRate.add(calcLegalRate());
      
      // Draw UI
      if (fastMode) {
        background(BACKGROUND);
        drawMaze(68, 68, 33);
        drawExactAgents(68, 68, 33);
        textFont(TITLE_FONT);
        fill(TEXT_COLOR);
        text("Generation " + gen, 1967, 100);
        if (successful) {
          textFont(SUB_FONT);
          text("Successfully reached exit!", 1280, 1405);
        }
        drawExplorationRate(1439, 192, explorationRate);
        drawLegalRate(1439, 812, successRate);
      }
      
      // Perform crossover and mutation
      Collections.shuffle(Arrays.asList(parents), agentRand);
      for (int i = 0; i < NUM_AGENTS / 2; i += 2) {
        int split = 1 + agentRand.nextInt() % (NUM_MOVES - 1);
        agents[NUM_AGENTS / 2 + i] = parents[i].crossover(parents[i + 1], split);
        agents[NUM_AGENTS / 2 + i + 1] = parents[i + 1].crossover(parents[i], split);
        if (agents[i].reached) {
          agents[NUM_AGENTS / 2 + i] = new Agent(agents[i].genome);
          agents[NUM_AGENTS / 2 + i + 1] = new Agent(agents[i].genome);
        }
        agents[NUM_AGENTS / 2 + i].mutate();
        agents[NUM_AGENTS / 2 + i + 1].mutate();
        
        agents[i] = new Agent(agents[i].genome);
        agents[i + 1] = new Agent(agents[i + 1].genome);
      }
      
      gen ++;
      move = 0;
      updated = true;
    }
  }
  if (updated && gen < 70) {
    updated = false;
  }
  
  if (!fastMode && !updated) {
    // Smooth move agents
    slideAgents();
    
    // Draw UI
    background(BACKGROUND);
    drawMaze(68, 68, 33);
    drawAgents(68, 68, 33);
    textFont(TITLE_FONT);
    fill(TEXT_COLOR);
    text("Generation " + gen, 1967, 100);
    if (successful) {
      textFont(SUB_FONT);
      text("Successfully reached exit!", 1280, 1405);
    }
    drawExplorationRate(1439, 192, explorationRate);
    drawLegalRate(1439, 812, successRate);
  }
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    fastMode = !fastMode;
  } else {
    if (updated == true) {
      updated = false;
    }
  }
}
