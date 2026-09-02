BARBERFLOW — HTML + SUPABASE + GITHUB PAGES

O projeto agora e 100% HTML/CSS/JavaScript no frontend e usa Supabase como banco online.
O cadastro de cliente acontece dentro da tela de "Novo agendamento": clique em "+ Novo",
cadastre o cliente e ele sera selecionado automaticamente no agendamento.

1) CRIAR O BANCO
- Crie um projeto no Supabase.
- Abra SQL Editor.
- Abra o arquivo supabase.sql deste projeto.
- Cole todo o SQL e execute.

2) PEGAR AS CHAVES
No Supabase, abra Project Settings > API.
Copie:
- Project URL
- chave anon public

Edite config.js:
window.BARBERFLOW_CONFIG = {
  SUPABASE_URL: "SUA_URL",
  SUPABASE_ANON_KEY: "SUA_CHAVE_ANON_PUBLIC"
};

NUNCA coloque a chave service_role no GitHub Pages.

3) TESTAR LOCALMENTE
- Tenha Python instalado.
- Dê dois cliques em INICIAR.bat.
- O navegador abrirá http://127.0.0.1:8000

4) COLOCAR NO GITHUB PAGES
- Crie um repositorio no GitHub.
- Envie TODOS os arquivos deste projeto para a raiz do repositorio.
- Va em Settings > Pages.
- Em Source, escolha Deploy from a branch.
- Branch: main / root.
- Salve e aguarde a publicação.

5) IMPORTANTE SOBRE SEGURANCA
Este pacote usa politicas anon simples para facilitar a primeira configuracao.
Isso significa que qualquer pessoa que tenha acesso ao site pode, tecnicamente, interagir
com as tabelas permitidas. Para uma barbearia real, o proximo passo recomendado e adicionar
login com Supabase Auth e RLS por usuario/estabelecimento.

6) SOBRE OS DADOS
Diferente do localStorage, aqui os dados ficam no Supabase. Portanto, quando voce abrir
o site em outro computador ou celular, os mesmos clientes e agendamentos aparecem.

SERVICOS INICIAIS
Degradê — R$ 45
Social — R$ 40
Corte infantil — R$ 40
Freestyle / Desenho — R$ 5
Sobrancelha — R$ 15
Barba simples — R$ 20
Barboterapia — R$ 30
Corte máquina — R$ 30

BARBEIROS
André
Valmor
Gustavo
Leonardo

COMBINAÇÃO DE SERVIÇOS
Agora é possível selecionar vários serviços no mesmo agendamento.
Exemplo: Degradê + Sobrancelha.
O sistema soma automaticamente os preços e as durações.
