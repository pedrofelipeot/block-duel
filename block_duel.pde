import org.jbox2d.dynamics.*;
import org.jbox2d.collision.shapes.PolygonShape;
import org.jbox2d.common.Vec2;
import shiffman.box2d.*;

Box2DProcessing box2d;
ArrayList<Body> allBlocks;
Body fallingBlock;
boolean canDropNewBlock = true;
float blockSize = 25; // tamanho de cada quadradinho em pixels

void setup() {
  size(800, 600);
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -20);
box2d.world.setAllowSleep(false);
  allBlocks = new ArrayList<Body>();
  createGround();
}

void draw() {
  background(255);
  box2d.step();

  for (Body b : allBlocks) {
    drawBlock(b);
  }

  if (fallingBlock != null) {
    drawBlock(fallingBlock);

    if (fallingBlock.getLinearVelocity().length() < 0.05f &&
        abs(fallingBlock.getAngularVelocity()) < 0.05f) {
      allBlocks.add(fallingBlock);
      fallingBlock = null;
      canDropNewBlock = true;
    }
  }

  if (canDropNewBlock) {
    dropBlock();
    canDropNewBlock = false;
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
void dropBlock() {
  float startX = width / 2f;
  float s = box2d.scalarPixelsToWorld(blockSize / 2f); // metade do tamanho do quadrado
  float startY = 50;

  BodyDef bd = new BodyDef();
  bd.type = BodyType.DYNAMIC;
  bd.position = box2d.coordPixelsToWorld(startX, startY);
  fallingBlock = box2d.createBody(bd);
  fallingBlock.setBullet(true);

  int type = int(random(3)); // 0: quadrado, 1: L, 2: T

  switch (type) {
    case 0:
      // Quadrado 2x2
      createBoxFixture(fallingBlock, -s, -s, s, s);
      createBoxFixture(fallingBlock, s, -s, s, s);
      createBoxFixture(fallingBlock, -s, s, s, s);
      createBoxFixture(fallingBlock, s, s, s, s);
      break;

    case 1:
      // L: 3 blocos verticais + 1 à direita na base
      createBoxFixture(fallingBlock, 0, -3 * s, s, s);  // topo
      createBoxFixture(fallingBlock, 0, -s, s, s);      // meio
      createBoxFixture(fallingBlock, 0, s, s, s);       // base
      createBoxFixture(fallingBlock, 2 * s, s, s, s);   // pé do L (à direita)
      break;

    case 2:
      // T: 3 blocos verticais + 2 laterais no topo
      createBoxFixture(fallingBlock, 0, s, s, s);        // base
      createBoxFixture(fallingBlock, 0, -s, s, s);       // meio
      createBoxFixture(fallingBlock, 0, -3 * s, s, s);   // topo
      createBoxFixture(fallingBlock, -2 * s, -3 * s, s, s); // esquerda topo
      createBoxFixture(fallingBlock, 2 * s, -3 * s, s, s);  // direita topo
      break;
  }

  fallingBlock.setLinearDamping(1.8f);
  fallingBlock.setAngularDamping(3.5f);
}

void createBoxFixture(Body body, float x, float y, float halfW, float halfH) {
  PolygonShape ps = new PolygonShape();
  ps.setAsBox(halfW, halfH, new Vec2(x, y), 0);

  FixtureDef fd = new FixtureDef();
  fd.shape = ps;
  fd.density = 2.0f;
  fd.friction = 0.8f;
  fd.restitution = 0.0f;

  body.createFixture(fd);
}

void keyPressed() {
  if (fallingBlock == null) return;

  float impulseStrength = 5.0f;
  Vec2 impulse = new Vec2(0, 0);

  if (keyCode == LEFT) {
    impulse.set(-impulseStrength, 0);
  } else if (keyCode == RIGHT) {
    impulse.set(impulseStrength, 0);
  }

  fallingBlock.applyLinearImpulse(impulse, fallingBlock.getWorldCenter(), true);
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
  fd.density = 0;
  fd.friction = 1.0f;

  ground.createFixture(fd);
}
