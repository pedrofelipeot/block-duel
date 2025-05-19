import org.jbox2d.dynamics.*;
import org.jbox2d.collision.shapes.PolygonShape;
import org.jbox2d.common.Vec2;
import shiffman.box2d.*;

import java.util.ArrayList;

Box2DProcessing box2d;
ArrayList<Body> allBlocks;
Body fallingBlock1;
Body fallingBlock2;
boolean canDropNewBlock1 = true;
boolean canDropNewBlock2 = true;
boolean gameOver = false;
String winnerText = "";
float blockSize = 15;
float winLineY = 500;

// Imagens da tela inicial
PImage fundoImg;
PImage botaoImg;
boolean telaInicial = true;
float botaoX, botaoY, botaoW = 200, botaoH = 100;

void setup() {
  size(800, 600);

  // Carregar imagens
  fundoImg = loadImage("fotos/fundo.png");
  botaoImg = loadImage("fotos/botao.png");

  botaoX = width / 2 - botaoW / 2;
  botaoY = height / 2 - botaoH / 2;

  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -20);
  box2d.world.setAllowSleep(false);

  allBlocks = new ArrayList<Body>();
  createGround();
  createDivider();
}

void draw() {
  if (telaInicial) {
    image(fundoImg, 0, 0, width, height);
    image(botaoImg, botaoX, botaoY, botaoW, botaoH);
    return;
  }

  background(255);
  box2d.step();

  // Linha de vitória
  stroke(0, 200, 0);
  strokeWeight(2);
  line(0, winLineY, width, winLineY);

  // Divisória vertical
  stroke(0);
  strokeWeight(3);
  line(width/2, 0, width/2, height);

  // Desenhar todos os blocos empilhados
  for (Body b : allBlocks) {
    drawBlock(b);
    Vec2 pos = box2d.getBodyPixelCoord(b);
    if (pos.y <= winLineY && !gameOver) {
      gameOver = true;
      winnerText = (box2d.getBodyPixelCoord(b).x < width/2) ? "Jogador 1 venceu!" : "Jogador 2 venceu!";
      break;
    }
  }

  // Exibir mensagem de vitória
  if (gameOver) {
    textAlign(CENTER);
    textSize(32);
    fill(0, 150, 0);
    text(winnerText, width/2, height/2);
    return;
  }

  // Desenhar e controlar bloco do jogador 1
  if (fallingBlock1 != null) {
    drawBlock(fallingBlock1);
    if (fallingBlock1.getLinearVelocity().length() < 0.05f &&
        abs(fallingBlock1.getAngularVelocity()) < 0.05f) {
      allBlocks.add(fallingBlock1);
      fallingBlock1 = null;
      canDropNewBlock1 = true;
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
  fd.density = 0.2f;
  fd.friction = 1.2f;
  fd.restitution = 0.0f;

  body.createFixture(fd);
}

void createGround() {
  float groundWidth = width;
  float groundHeight = 20;
  Vec2 groundPos = new Vec2(width / 2, height - groundHeight / 2);

  BodyDef bd = new BodyDef();
  bd.position = box2d.coordPixelsToWorld(groundPos);
  Body ground = box2d.createBody(bd);

  PolygonShape shape = new PolygonShape();
  shape.setAsBox(box2d.scalarPixelsToWorld(groundWidth / 2), box2d.scalarPixelsToWorld(groundHeight / 2));

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
  }
}
