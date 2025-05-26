import processing.video.*;
import processing.sound.*;

import org.jbox2d.dynamics.*;
import org.jbox2d.collision.shapes.PolygonShape;
import org.jbox2d.common.Vec2;
import shiffman.box2d.*;

import java.util.ArrayList;

ArrayList<Confete> confetes;
int maxConfetes = 30;

ArrayList<ConfeteVitoria> confetesVitoria;
int maxConfetesVitoria = 90;



Box2DProcessing box2d;
ArrayList<Body> allBlocks;
Body fallingBlock1;
Body fallingBlock2;
boolean canDropNewBlock1 = true;
boolean canDropNewBlock2 = true;
boolean gameOver = false;
String winnerText = "";
float blockSize = 15;
float winLineY = 100;

// Imagens da tela inicial
PImage logoImg;
PImage botaoImg;
PImage chaoImg;
PImage chegadaImg;

PImage vencedor1Img;
PImage vencedor2Img;


float yChaoImagem = 590;     // Onde a imagem do chão começa na tela
float yChaoFisico = 570;     // Onde está o chão físico (colisão)


boolean telaInicial = true;
float botaoX, botaoY, botaoW = 200, botaoH = 100;

// Sons
SoundFile somIntro;
SoundFile somJogo;
SoundFile somColisao;
SoundFile somVitoria;
Movie videoIntro;  // Vídeo da tela inicial
Movie videoJogo;   // Vídeo de fundo durante o jogo

boolean tocandoSomJogo = false;

void setup() {
  size(800, 600);

  // Carregar imagens
  botaoImg = loadImage("fotos/botao.png");
  logoImg = loadImage("fotos/logo.png");
  chaoImg = loadImage("fotos/chao.png"); // ajuste o caminho conforme sua estrutura
  vencedor1Img = loadImage("fotos/jogador1.png");
vencedor2Img = loadImage("fotos/jogador2.png");

chegadaImg = loadImage("fotos/chegada.png"); // ajuste o caminho conforme necessário



  botaoX = width / 2 - botaoW / 2;
  botaoY = height / 2 - botaoH / 2;

  // Vídeo do jogo
  videoJogo = new Movie(this, "fundoJogo.mp4");
  videoJogo.loop();
  videoJogo.pause();

  // Sons
  somIntro = new SoundFile(this, "sons/intro.mp3");
  somJogo = new SoundFile(this, "sons/jogo.mp3");
  somColisao = new SoundFile(this, "sons/colisao.mp3");
  somVitoria = new SoundFile(this, "sons/vitoria.mp3");

  somIntro.loop();

  // Vídeo da introdução
  videoIntro = new Movie(this, "video.mp4");
  videoIntro.loop();

  // Física
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -90);
  box2d.world.setAllowSleep(false);

  allBlocks = new ArrayList<Body>();
  createGround();
  createDivider();
  confetes = new ArrayList<Confete>();
for (int i = 0; i < maxConfetes; i++) {
  confetes.add(new Confete());
}

confetesVitoria = new ArrayList<ConfeteVitoria>();
for (int i = 0; i < maxConfetesVitoria; i++) {
  confetesVitoria.add(new ConfeteVitoria());
}



}

void draw() {
  if (telaInicial) {
    image(videoIntro, 0, 0, width, height);
      for (Confete c : confetes) {
  c.update();
  c.display();
}

    float logoW = 380;
    float logoH = 250;
    float logoX = width / 2 - logoW / 2;
    float logoY = 10;
    image(logoImg, logoX, logoY, logoW, logoH);

    botaoW = 320;
    botaoH = 180;
    botaoX = width / 2 - botaoW / 2;
    botaoY = height - botaoH ;
    image(botaoImg, botaoX, botaoY, botaoW, botaoH);

    return;
  }

  // Desenhar o vídeo de fundo do jogo
  image(videoJogo, 0, 0, width, height);
  float chaoAltura = 30;  // altura que quiser para o chão (ex: 150 pixels)
float chaoY = 570;

imageMode(CORNER);
image(chaoImg, 0, chaoY, width, chaoAltura);



  box2d.step();

  // Linha de vitória
  stroke(0, 200, 0);
  strokeWeight(2);
  line(0, winLineY, width, winLineY);
  
  float chegadaW = 60;  // largura da imagem de chegada
float chegadaH = 60;  // altura da imagem de chegada
float chegadaX = width / 2 - chegadaW / 2;
float chegadaY = winLineY - chegadaH / 2;

image(chegadaImg, chegadaX, chegadaY, chegadaW, chegadaH);


  // Divisória vertical
  stroke(0);
  strokeWeight(3);
  line(width / 2, 0, width / 2, height);

  // Blocos empilhados
  for (Body b : allBlocks) {
    drawBlock(b);
    Vec2 pos = box2d.getBodyPixelCoord(b);
    if (pos.y <= winLineY && !gameOver) {
      gameOver = true;
      winnerText = (pos.x < width / 2) ? "Jogador 1 venceu!" : "Jogador 2 venceu!";
      somVitoria.play();
      videoJogo.pause(); // Pausar o vídeo quando o jogo termina
      break;
    }
  }

if (gameOver) {
  imageMode(CORNER);

  if (winnerText.equals("Jogador 1 venceu!")) {
    image(vencedor1Img, 0, 0, width, height);
  } else if (winnerText.equals("Jogador 2 venceu!")) {
    image(vencedor2Img, 0, 0, width, height);
  }

 for (ConfeteVitoria c : confetesVitoria) {
    c.update();
    c.display();
  }

  return;
}




  // Jogador 1
  if (fallingBlock1 != null) {
    drawBlock(fallingBlock1);
    if (fallingBlock1.getLinearVelocity().length() < 0.05f &&
        abs(fallingBlock1.getAngularVelocity()) < 0.05f) {
      allBlocks.add(fallingBlock1);
      fallingBlock1 = null;
      canDropNewBlock1 = true;
      somColisao.play();
    }
  }

  // Jogador 2
  if (fallingBlock2 != null) {
    drawBlock(fallingBlock2);
    if (fallingBlock2.getLinearVelocity().length() < 0.05f &&
        abs(fallingBlock2.getAngularVelocity()) < 0.05f) {
      allBlocks.add(fallingBlock2);
      fallingBlock2 = null;
      canDropNewBlock2 = true;
      somColisao.play();
    }
  }

  // Criar novos blocos
  if (canDropNewBlock1) {
    fallingBlock1 = dropBlock(true);
    canDropNewBlock1 = false;
  }
  if (canDropNewBlock2) {
    fallingBlock2 = dropBlock(false);
    canDropNewBlock2 = false;
  }
}


void drawBlock(Body b) {
  Vec2 pos = box2d.getBodyPixelCoord(b);
  float angle = b.getAngle();

  pushMatrix();
  translate(pos.x, pos.y);
  rotate(angle);
  fill(150, 0, 0);
  stroke(0);
  strokeWeight(1);

  for (Fixture f = b.getFixtureList(); f != null; f = f.getNext()) {
    PolygonShape ps = (PolygonShape) f.getShape();
    beginShape();
    for (int i = 0; i < ps.getVertexCount(); i++) {
      Vec2 v = ps.getVertex(i);
      Vec2 pixel = box2d.vectorWorldToPixels(v);
      vertex(pixel.x, pixel.y);
    }
    endShape(CLOSE);
  }

  popMatrix();
}

Body dropBlock(boolean isLeftSide) {
  float baseX = isLeftSide ? width * 0.25f : width * 0.75f;
  float variation = random(-10, 10);
  float startX = baseX + variation;
  float s = box2d.scalarPixelsToWorld(blockSize / 2f);
  float startY = 50;
  float padding = 0.01f;

  BodyDef bd = new BodyDef();
  bd.type = BodyType.DYNAMIC;
  bd.position = box2d.coordPixelsToWorld(startX, startY);
  Body newBlock = box2d.createBody(bd);

  int type = int(random(3));
  switch (type) {
    case 0:
      createBoxFixture(newBlock, -s - padding, -s - padding, s - padding, s - padding);
      createBoxFixture(newBlock, s + padding, -s - padding, s - padding, s - padding);
      createBoxFixture(newBlock, -s - padding, s + padding, s - padding, s - padding);
      createBoxFixture(newBlock, s + padding, s + padding, s - padding, s - padding);
      break;
    case 1:
      createBoxFixture(newBlock, 0, -3 * s - 2 * padding, s - padding, s - padding);
      createBoxFixture(newBlock, 0, -s - padding, s - padding, s - padding);
      createBoxFixture(newBlock, 0, s + padding, s - padding, s - padding);
      createBoxFixture(newBlock, 2 * s + 2 * padding, s + padding, s - padding, s - padding);
      break;
    case 2:
      createBoxFixture(newBlock, 0, s + padding, s - padding, s - padding);
      createBoxFixture(newBlock, 0, -s - padding, s - padding, s - padding);
      createBoxFixture(newBlock, 0, -3 * s - 2 * padding, s - padding, s - padding);
      createBoxFixture(newBlock, -2 * s - 2 * padding, -3 * s - 2 * padding, s - padding, s - padding);
      createBoxFixture(newBlock, 2 * s + 2 * padding, -3 * s - 2 * padding, s - padding, s - padding);
      break;
  }

  newBlock.setLinearDamping(1.8f);
  newBlock.setAngularDamping(3.5f);
  return newBlock;
}

void createBoxFixture(Body body, float x, float y, float halfW, float halfH) {
  PolygonShape ps = new PolygonShape();
  ps.setAsBox(halfW, halfH, new Vec2(x, y), 0);

  FixtureDef fd = new FixtureDef();
  fd.shape = ps;
  fd.density = 1.2f;
  fd.friction = 1.2f;
  fd.restitution = 0.0f;

  body.createFixture(fd);
}

void createGround() {
  float groundWidth = width;
  float groundHeight = 20;
Vec2 groundPos = new Vec2(width / 2, yChaoFisico + groundHeight / 2);



  BodyDef bd = new BodyDef();
  bd.position = box2d.coordPixelsToWorld(groundPos);
  Body ground = box2d.createBody(bd);

  PolygonShape shape = new PolygonShape();
  shape.setAsBox(
    box2d.scalarPixelsToWorld(groundWidth / 2),
    box2d.scalarPixelsToWorld(groundHeight / 2)
  );

  FixtureDef fd = new FixtureDef();
  fd.shape = shape;
  fd.friction = 0.3f;

  ground.createFixture(fd);
}


void createDivider() {
  float dividerWidth = 10;
  float dividerHeight = height;
  Vec2 dividerPos = new Vec2(width / 2, height / 2);

  BodyDef bd = new BodyDef();
  bd.position = box2d.coordPixelsToWorld(dividerPos);
  Body divider = box2d.createBody(bd);

  PolygonShape shape = new PolygonShape();
  shape.setAsBox(box2d.scalarPixelsToWorld(dividerWidth / 2), box2d.scalarPixelsToWorld(dividerHeight / 2));

  FixtureDef fd = new FixtureDef();
  fd.shape = shape;
  fd.friction = 0.3f;
  fd.restitution = 0.0f;
  fd.density = 0;

  divider.createFixture(fd);
}

void keyPressed() {
  if (gameOver || telaInicial) return;

  float moveSpeed = box2d.scalarPixelsToWorld(blockSize * 3);

  if (fallingBlock1 != null) {
    Vec2 vel = fallingBlock1.getLinearVelocity();
    if (key == 'a' || key == 'A') {
      fallingBlock1.setLinearVelocity(new Vec2(-moveSpeed, vel.y));
    } else if (key == 'd' || key == 'D') {
      fallingBlock1.setLinearVelocity(new Vec2(moveSpeed, vel.y));
    } else if (key == 'w' || key == 'W') {
      float newAngle = fallingBlock1.getAngle() - (float)(Math.PI / 2);
      fallingBlock1.setTransform(fallingBlock1.getPosition(), newAngle);
      fallingBlock1.setLinearVelocity(new Vec2(0, vel.y));
      fallingBlock1.setAngularVelocity(0);
    }
  }

  if (fallingBlock2 != null) {
    Vec2 vel = fallingBlock2.getLinearVelocity();
    if (keyCode == LEFT) {
      fallingBlock2.setLinearVelocity(new Vec2(-moveSpeed, vel.y));
    } else if (keyCode == RIGHT) {
      fallingBlock2.setLinearVelocity(new Vec2(moveSpeed, vel.y));
    } else if (keyCode == UP) {
      float newAngle = fallingBlock2.getAngle() - (float)(Math.PI / 2);
      fallingBlock2.setTransform(fallingBlock2.getPosition(), newAngle);
      fallingBlock2.setLinearVelocity(new Vec2(0, vel.y));
      fallingBlock2.setAngularVelocity(0);
    }
  }
}

void mousePressed() {
  if (telaInicial && mouseX >= botaoX && mouseX <= botaoX + botaoW &&
      mouseY >= botaoY && mouseY <= botaoY + botaoH) {
    telaInicial = false;
    videoIntro.stop();
    somIntro.stop();
    somJogo.loop();
    tocandoSomJogo = true;
    videoJogo.play(); // Começa vídeo do fundo
  }
}

void movieEvent(Movie m) {
  m.read();
}
class Confete {
  float x, y;
  float speedY;
  float angle, rotationSpeed;
  float w, h;
  color col;

  Confete() {
    reset();
  }

  void reset() {
  x = random(width);
  y = random(-height, 0);
  speedY = random(2, 4);
  angle = random(TWO_PI);
  rotationSpeed = random(-0.03, 0.03);

  w = random(12, 18);
  h = random(12, 18);

  // Cores variadas
  color[] cores = {
    color(255, 0, 0),    // vermelho
    color(0, 0, 255),    // azul
    color(0, 200, 0),    // verde
    color(255, 200, 0),  // amarelo
    color(255, 100, 0),  // laranja
    color(180, 0, 180),  // roxo
    color(0, 200, 200)   // ciano
  };
  col = cores[int(random(cores.length))];
}


  void update() {
    y += speedY;
    angle += rotationSpeed;
    if (y > height + h) {
      reset();
    }
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle);
    rectMode(CENTER);
    fill(col);
    stroke(0);
    strokeWeight(1.2);
    rect(0, 0, w, h);
    popMatrix();
  }
}

class ConfeteVitoria {
  float x, y;
  float speedY;
  float angle, rotationSpeed;
  float size;
  color col;

  ConfeteVitoria() {
    reset();
  }

  void reset() {
    x = random(width);
    y = random(-height, 0);
    speedY = random(1, 3);
    angle = random(TWO_PI);
    rotationSpeed = random(-0.05, 0.05);
    size = random(8, 15);

    color[] cores = {
      color(255, 0, 0),    // vermelho
      color(0, 0, 255),    // azul
      color(0, 200, 0),    // verde
      color(255, 200, 0),  // amarelo
      color(255, 100, 0),  // laranja
      color(180, 0, 180),  // roxo
      color(0, 200, 200)   // ciano
    };
    col = cores[int(random(cores.length))];
  }

  void update() {
    y += speedY;
    angle += rotationSpeed;
    if (y > height + size) {
      reset();
    }
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle);
    noStroke();
    fill(col);

    // Forma orgânica: ex. triângulo alongado com curvas
    beginShape();
    vertex(-size/2, -size/4);
    bezierVertex(-size/3, 0, -size/4, size/2, 0, size/2);
    bezierVertex(size/4, size/2, size/3, 0, size/2, -size/4);
    bezierVertex(size/3, -size/2, size/4, -size/2, 0, -size/3);
    bezierVertex(-size/4, -size/2, -size/3, -size/2, -size/2, -size/4);
    endShape(CLOSE);

    popMatrix();
  }
}
