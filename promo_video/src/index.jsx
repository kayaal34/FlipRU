import { Composition, registerRoot } from 'remotion';
import { FlipRU, TOTAL } from './FlipRU';

const Root = () => (
  <Composition
    id="FlipRU"
    component={FlipRU}
    durationInFrames={TOTAL}
    fps={30}
    width={1080}
    height={1920}
  />
);

registerRoot(Root);
