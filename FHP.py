import numpy as np
import random
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import time


class FHP_Simulation:
    def __init__(self, width, height) -> None:
        self.w = width
        self.h = height

        # board variables
        self.a = np.zeros((width, height), dtype=np.int8)
        self.b = np.zeros_like(self.a)
        self.c = np.zeros_like(self.a)
        self.d = np.zeros_like(self.a)
        self.e = np.zeros_like(self.a)
        self.f = np.zeros_like(self.a)

        # temp variables
        self.K_a = np.zeros_like(self.a)
        self.K_b = np.zeros_like(self.a)
        self.K_c = np.zeros_like(self.a)
        self.K_d = np.zeros_like(self.a)
        self.K_e = np.zeros_like(self.a)
        self.K_f = np.zeros_like(self.a)

        # debug
        self.iter_t = time.time()

    # prob of setting a direction in a cell to 1
    def init_board_urand(self, prob) -> None:
        for x in range(self.w):
            for y in range(self.h):
                self.a[x][y] = random.random() < prob
                self.b[x][y] = random.random() < prob
                self.c[x][y] = random.random() < prob
                self.d[x][y] = random.random() < prob
                self.e[x][y] = random.random() < prob
                self.f[x][y] = random.random() < prob

    def init_board_sq(self) -> None:
        for x in range(int(self.w * 0.25), int(self.w * 0.75)):
            for y in range(int(self.h * 0.25), int(self.h * 0.75)):
                self.a[x][y] = 1
                self.d[x][y] = 1

    def collision_phase(self) -> None:
        for x in range(self.w):
            for y in range(self.h):
                a, b, c, d, e, f = self.a[x][y], self.b[x][y], self.c[x][y], self.d[x][y], self.e[x][y], self.f[x][y]

                tb_ad = (a & d) & (~(b | c | e | f))
                tb_be = (b & e) & (~(a | c | d | f))
                tb_cf = (c & f) & (~(a | b | d | e))

                triple = (a ^ b) & (b ^ c) & (c ^ d) & (d ^ e) & (e ^ f)

                rnd = random.getrandbits(8)
                no_rnd = ~rnd

                cha = (tb_ad | triple | (rnd & tb_be) | (no_rnd & tb_cf))
                chb = (tb_be | triple | (rnd & tb_cf) | (no_rnd & tb_ad))
                chc = (tb_cf | triple | (rnd & tb_ad) | (no_rnd & tb_be))
                chd = cha
                che = chb
                chf = chc

                self.K_a[x][y] = a ^ cha
                self.K_b[x][y] = b ^ chb
                self.K_c[x][y] = c ^ chc
                self.K_d[x][y] = d ^ chd
                self.K_e[x][y] = e ^ che
                self.K_f[x][y] = f ^ chf

    def propagation_phase(self) -> None:
        for x in range(self.w):
            for y in range(self.h):
                # Propagation with wall conditions
                self.a[x][y] = int(self.K_a[x][(y - 1)])       if y > 0 else int(self.K_d[x][y])
                self.b[x][y] = int(self.K_b[(x + 1)][(y - 1)]) if x < self.w - 1 and y > 0 else int(self.K_e[x][y])
                self.c[x][y] = int(self.K_c[(x + 1)][(y + 1)]) if x < self.w - 1 and y < self.h - 1 else int(self.K_f[x][y])
                self.d[x][y] = int(self.K_d[x][(y + 1)])       if y < self.h - 1 else int(self.K_a[x][y])
                self.e[x][y] = int(self.K_e[(x - 1)][(y + 1)]) if x > 0 and y < self.h - 1 else int(self.K_b[x][y])
                self.f[x][y] = int(self.K_f[(x - 1)][(y - 1)]) if x > 0 and y > 0 else int(self.K_c[x][y])

    def evolve(self) -> None:
        self.collision_phase()
        self.propagation_phase()

    def save_img(self, idx) -> None:
        plt.imsave('temp/' + str(idx) + '.png', self.a + self.b + self.c + self.d + self.e + self.f, cmap="Greys")

    def generate_gif(self, steps=200) -> None:
        ims = []
        fig = plt.figure()

        for i in range(steps):
            im = plt.imshow(self.a + self.b + self.c + self.d + self.e + self.f, cmap="Greys", animated=True)
            ims.append([im])
            self.evolve()

            d_t = time.time() - self.iter_t
            est_t = int(d_t * (steps - i))
            if (i % int(steps / 10) == 0):
                print(f'current progress: {i}/{steps}, estimate time {est_t}')
            self.iter_t = time.time()

        ani = animation.ArtistAnimation(fig, ims, interval=50, blit=True, repeat_delay=0)

        ani.save('animation.gif')


if __name__ == '__main__':
    hpp_simulator = FHP_Simulation(256, 256)
    hpp_simulator.init_board_sq()

    hpp_simulator.generate_gif(300)