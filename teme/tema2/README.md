Subtirica Florin-Ioan
332CD

**Main**
După inițializarea datelor necesare device-ului, se alocă (`cudaMalloc`) și se copiază memoria (`cudaMemcpy` cu cudaMemcpyHostToDevice) pe dispozitivul CUDA, lansăm kernel-ul CUDA (`findNonce`) pentru căutarea nonce-urilor și se așteaptă ca kernel-ul să se finalizeze (`cudaDeviceSynchronize()`). Ulterior, rezultatele (hash-ul blocului și nonce-ul găsit) sunt copiate înapoi pe host (`cudaMemcpy` cu cudaMemcpyDeviceToHost) și memoria alocată pe dispozitivul CUDA este eliberată (cudaFree). În final, este afișat rezultatul căutării nonce-ului (`printResult`).

**findNonce**
În interiorul kernel-ului, fiecare thread calculează un interval de nonces de căutat. Intervalul este calculat pe baza numărului total de threads și numărul de blocuri definite (`start` și `end`). Apoi, fiecare thread iterează prin acest interval, adăugând nonce-ul la conținutul blocului, calculând hash-ul și verificând dacă acesta îndeplinește criteriile de dificultate.

Dacă un thread găsește un nonce valid, acesta actualizează valoarea nonce-ului și hash-ul blocului și se termină. Altfel, căutarea continuă până la găsirea unui nonce valid sau până când toate nonces sunt încercate.
