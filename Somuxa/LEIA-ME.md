# Somuxa: como colocar no ar

O Somuxa é um site que se instala na tela inicial do celular (PWA). Cada um entra com a própria conta, os dois ficam ligados no mesmo "casal" e tudo o que um lança aparece para o outro na hora, no iPhone, no Android, no Safari, no Firefox ou no computador.

Você vai usar dois serviços gratuitos:

- **Supabase**: guarda os dados e faz o login.
- **Netlify** (ou Cloudflare Pages): hospeda o site.

Tempo estimado: 20 a 30 minutos, uma vez só.

---

## O que tem na pasta

| Arquivo | Para que serve |
|---|---|
| `index.html` | O app inteiro (a interface que criamos). |
| `config.js` | **O único arquivo que você edita.** Recebe os dados do seu Supabase. |
| `schema.sql` | Cria as tabelas e as regras de segurança no Supabase. |
| `manifest.webmanifest`, `sw.js`, `icon-*.png`, `icon.svg`, `apple-touch-icon.png` | Fazem o site virar app (ícone, tela cheia, abrir sem internet). |
| `_headers` | Garante que atualizações cheguem sem ficar presas em cache. |

---

## Passo 1. Criar o projeto no Supabase

1. Entre em **supabase.com** e crie uma conta (pode ser com o Google ou o GitHub).
2. Clique em **New project**.
3. Dê um nome (por exemplo, `somuxa`), crie uma **senha do banco** (guarde num lugar seguro) e escolha a região **South America (São Paulo)**.
4. Espere cerca de 2 minutos até o projeto ficar pronto.

## Passo 2. Criar as tabelas

1. No menu da esquerda, abra **SQL Editor** e clique em **New query**.
2. Abra o arquivo `schema.sql`, copie **tudo** e cole no editor.
3. Clique em **Run**. Deve aparecer "Success. No rows returned".

Isso cria o casal, as tabelas e a segurança: cada casal só enxerga os próprios dados, e um grupo aceita no máximo quatro pessoas.

## Passo 3. Ajustar o login por e-mail

1. Vá em **Authentication → Sign In / Providers** e confira que **Email** está ligado.
2. Deixe **Confirm email** **ligado** (é ele que faz o app pedir o código de 6 dígitos ao criar a conta).
3. Em **Authentication → Emails → Templates**, abra **Confirm sign up** e **Reset password** e troque o texto de cada um para mostrar o código no lugar do link. Exemplo:

   ```
   <h2>Seu código do Somuxa</h2>
   <p>Digite este código no app: <b>{{ .Token }}</b></p>
   <p>Ele vale por pouco tempo. Se não foi você, ignore este e-mail.</p>
   ```
   Não use `{{ .ConfirmationURL }}` nesses dois modelos.
4. **Importante: envio de e-mails.** O envio padrão do Supabase só entrega para e-mails da sua própria equipe e limita a 2 mensagens por hora. Para outras pessoas receberem o código, configure um SMTP próprio em **Authentication → Emails → SMTP Settings** (Resend, Brevo, Postmark, SendGrid ou Amazon SES; a maioria pede um domínio verificado). Sem isso, ninguém de fora recebe o código.

## Passo 4. Copiar as duas chaves para o `config.js`

1. Vá em **Project Settings → API** (ícone de engrenagem).
2. Copie o **Project URL** (algo como `https://abcdxyz.supabase.co`).
3. Copie a chave **anon public** (um texto grande que começa com `eyJ...`).
4. Abra o `config.js` e cole entre as aspas:

```js
window.APP_CONFIG = {
  SUPABASE_URL: "https://abcdxyz.supabase.co",
  SUPABASE_ANON_KEY: "eyJ...sua chave anon..."
};
```

> **Use somente a chave `anon public`.** Nunca use a `service_role`. A `anon` pode ficar no site, porque a segurança está nas regras do `schema.sql` (RLS): sem login, ninguém lê nem grava nada.

## Passo 5. Publicar o site

**Opção mais fácil: Netlify Drop**

1. Entre em **app.netlify.com/drop** (crie a conta gratuita se pedir).
2. Arraste a **pasta inteira** `somuxa` (com o `config.js` já preenchido) para a página.
3. Em alguns segundos você recebe um endereço como `https://nome-aleatorio.netlify.app`. Em **Site configuration → Change site name** dá para escolher um nome mais bonito.

**Alternativa: Cloudflare Pages.** Em **Workers & Pages → Create → Pages → Upload assets**, envie a mesma pasta.

Para atualizar o app no futuro, é só enviar a pasta de novo.

## Passo 6. Avisar o Supabase qual é o endereço do site

Isso faz os e-mails de "confirmar conta" e "esqueci a senha" abrirem o seu site.

1. No Supabase, vá em **Authentication → URL Configuration**.
2. Em **Site URL**, cole o endereço do seu site (por exemplo, `https://seu-site.netlify.app`).
3. Em **Redirect URLs**, adicione o mesmo endereço e salve.

## Passo 7. Primeiro acesso (vocês dois)

1. **A primeira pessoa** abre o site, toca em **Criar conta**, informa e-mail e senha (mínimo 8 caracteres) e entra.
2. Escolhe **Criar nosso casal**. Aparece um **código** (como `5185C-09840`). Envie esse código ao parceiro(a). Ele fica guardado em **Ajustes**.
3. **A segunda pessoa** abre o site, cria a própria conta, escolhe **Meu parceiro já criou** e digita o código.
4. Pronto: os dois veem os mesmos dados, atualizados ao vivo.

Para apagar tudo e voltar ao início, vá em **Ajustes → Dados → Começar do zero**. Isso apaga renda, lançamentos, cartões, metas e nomes (e-mail e senha não mudam).

## Passo 8. Instalar na tela inicial

- **iPhone (Safari):** abra o site, toque em **Compartilhar** (o quadrado com a seta) e em **Adicionar à Tela de Início**. Tem que ser no Safari.
- **Android (Chrome):** menu **⋮ → Instalar app** (ou **Adicionar à tela inicial**).
- **Android (Firefox):** menu **⋮ → Instalar**.
- **Firefox no computador:** não instala como app. Use o site normalmente ou salve nos favoritos.
- **Chrome ou Edge no computador:** aparece o ícone de instalar na barra de endereço.

O app abre em tela cheia, com o ícone próprio, e continua abrindo sem internet. Sem internet dá para ver os dados e fazer alterações, que são enviadas quando a conexão voltar.

---

## Testar antes de publicar (opcional)

Sem preencher o `config.js`, o app roda em **modo local**: sem login, com os dados guardados só naquele aparelho. Para ver no computador, abra um terminal na pasta e rode:

```
python3 -m http.server 8000
```

Depois acesse `http://localhost:8000`.

## Boas práticas

- **Dados na nuvem do Supabase:** o plano gratuito pode **pausar o projeto após cerca de uma semana sem nenhum acesso**. Se acontecer, entre no painel do Supabase e clique em **Restore project**. Os dados não se perdem. Abrir o app de vez em quando evita isso.
- **Backup:** o plano gratuito não oferece backup automático. Se quiserem uma cópia dos dados, no Supabase abra **Table Editor → estado** e exporte em CSV de tempos em tempos.
- **Conflitos:** se os dois editarem o mesmo mês no mesmo instante, vale a última gravação. As mudanças aparecem na hora para o outro, então isso é raro.
- **Senha esquecida:** na tela de entrada, toque em **Esqueci a senha**. Enviamos um código de 6 dígitos por e-mail; digite o código no app e escolha a senha nova.
- **Trocar de aparelho:** basta entrar com o mesmo e-mail e senha.

## Se algo não funcionar

| Sintoma | O que fazer |
|---|---|
| O app abre direto, sem pedir login | O `config.js` está vazio ou com valores errados. Confira o passo 4 e publique de novo. |
| "Algo deu errado" ao criar casal ou entrar | O `schema.sql` não foi executado até o fim. Rode de novo no SQL Editor. |
| Erro `42501: permission denied for table casais` | Faltam as permissões da API. Rode o `schema.sql` de novo (ele agora inclui as linhas `grant`) ou só o trecho "Permissões da API" dele. |
| O código não chega | Veja o spam. O envio padrão do Supabase só entrega para a sua equipe e limita 2 por hora: configure um SMTP próprio (passo 3). |
| O link do e-mail abre uma página errada | Confira o passo 6 (Site URL e Redirect URLs). |
| Atualizei o site mas o app mostra a versão antiga | Feche o app por completo e abra de novo. Se persistir, reabra pelo navegador e recarregue a página. |


## Grupo com até 4 pessoas

Em **Ajustes → Pessoas, nomes e cores**, escolha 2, 3 ou 4 pessoas. Cada pessoa entra no grupo com a própria conta e o mesmo código. Se o seu Supabase já estava criado com o limite antigo de duas pessoas, rode de novo o `schema.sql` inteiro no SQL Editor (é seguro repetir): ele atualiza o limite para quatro.


## Novidades desta versão

- **Conta nova começa limpa**: sem lançamentos, cartões ou nomes de exemplo. Um passo a passo aparece na tela inicial. Quem entra com código de grupo vê os dados do grupo.
- **Modo noturno**: botão de lua/sol no topo (e na tela de login); em Ajustes há Automático, Claro e Noturno.
- **Continua conectado**: a pessoa só sai ao tocar em Sair da conta (sai só neste aparelho).
- **Códigos por e-mail** para confirmar a conta e para recuperar a senha.

## Metas, modos e renda

- **Metas** (antiga Caixinha): várias metas, cada uma com valor, prazo, quanto cada pessoa já guardou e previsão de quando chega lá. A caixinha antiga vira a meta "Caixinha" sozinha.
- **Solo / Duo / Grupo** em Ajustes. Toque na bolinha ao lado do nome para trocar a cor (6 opções).
- **Renda** alterada em um mês vale para os meses seguintes, até você mudar de novo.
